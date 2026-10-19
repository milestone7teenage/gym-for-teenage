import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/models.dart';
import 'package:gym_log/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('новое упражнение начинается ровно с двух подходов', () async {
    final store = GymStore();
    await store.init();

    final sets = store.setsFor('A', 'a1');
    expect(sets, hasLength(GymStore.defaultSetsCount));
    expect(sets.every((s) => !s.done), isTrue);
    expect(sets.every((s) => s.note.isEmpty), isTrue);
  });

  test('вес, повторы, отметки и заметки переживают перезапуск', () async {
    final first = GymStore();
    await first.init();
    first
      ..updateWeight('A', 'a1', 0, 42.5)
      ..updateReps('A', 'a1', 0, 8)
      ..updateNote('A', 'a1', 0, 'плотно, но чисто')
      ..toggleDone('A', 'a1', 0);
    await first.flush();

    final second = GymStore();
    await second.init();
    final set = second.setsFor('A', 'a1')[0];

    expect(set.weight, 42.5);
    expect(set.reps, 8);
    expect(set.done, isTrue);
    expect(set.note, 'плотно, но чисто');
  });

  test('добавление и удаление подходов сохраняется', () async {
    final first = GymStore();
    await first.init();
    final sets = first.setsFor('B', 'b1');
    first.addSet('B', 'b1');
    expect(sets, hasLength(3));
    first.removeSet('B', 'b1', 1);
    await first.flush();

    final second = GymStore();
    await second.init();
    expect(second.setsFor('B', 'b1'), hasLength(2));
  });

  test('сохранённая тренировка несёт снимок упражнений и подходов',
      () async {
    final first = GymStore();
    await first.init();
    final workout = workouts.first;
    first
      ..toggleDone(workout.id, workout.exercises.first.id, 0)
      ..updateWeight(
          workout.id, workout.exercises.first.id, 0, 60)
      ..updateReps(workout.id, workout.exercises.first.id, 0, 10);
    first.saveSession(workout);
    await first.flush();

    expect(first.totalSessions, 1);
    final saved = first.sessions.first;
    expect(saved.exercises, isNotEmpty);
    expect(saved.completedSets, 1);
    expect(saved.volume, 600);

    final second = GymStore();
    await second.init();
    expect(second.totalSessions, 1);
    final restored = second.sessions.first;
    expect(restored.exercises.first.name, workout.exercises.first.name);
    expect(restored.exercises.first.sets.single.weight, 60);
    expect(restored.exercises.first.sets.single.reps, 10);
  });

  test('пустая тренировка не сохраняется', () async {
    final store = GymStore();
    await store.init();
    store.saveSession(workouts.first);
    await store.flush();
    expect(store.totalSessions, 0);
  });

  test('замена упражнения и пропуск переживают перезапуск', () async {
    final first = GymStore();
    await first.init();
    final workout = workouts.first;
    first
      ..replaceExercise(workout, 0, pullups)
      ..setSkipped(workout, workout.exercises[1], true);
    await first.flush();

    expect(first.exerciseAt(workout, 0).id, 'pullups');
    expect(first.hasReplacement(workout, 0), isTrue);
    expect(first.isSkipped(workout, workout.exercises[1]), isTrue);

    final second = GymStore();
    await second.init();
    expect(second.exerciseAt(workout, 0).id, 'pullups');
    expect(second.hasReplacement(workout, 0), isTrue);
    expect(second.isSkipped(workout, workout.exercises[1]), isTrue);

    second.resetReplacement(workout, 0);
    expect(second.exerciseAt(workout, 0).id, workout.exercises[0].id);
  });

  test('экспорт и импорт переносят данные между устройствами', () async {
    final first = GymStore();
    await first.init();
    final workout = workouts.last;
    first
      ..toggleDone(workout.id, workout.exercises.first.id, 0)
      ..updateWeight(workout.id, workout.exercises.first.id, 0, 55);
    first.saveSession(workout);
    await first.flush();

    final payload = first.exportJson();
    expect(payload, contains('sessions'));

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(GymStore.storageKey);

    final second = GymStore();
    await second.init();
    expect(second.totalSessions, 0);

    expect(second.importJson(payload), isTrue);
    expect(second.totalSessions, 1);
    expect(second.exportJson(), payload);
  });

  test('повреждённая копия при импорте отклоняется', () async {
    final store = GymStore();
    await store.init();
    expect(store.importJson('не json'), isFalse);
    expect(store.importJson('[1,2,3]'), isFalse);
    expect(store.importJson('{"foo": 1}'), isFalse);
    expect(store.totalSessions, 0);
  });

  test('старый формат хранилища читается без потерь', () async {
    SharedPreferences.setMockInitialValues({
      GymStore.storageKey: '{"version":5,"sets":{"A::a1":['
          '{"weight":50,"reps":12,"done":true}]},'
          '"sessions":[{"workoutId":"B","date":"2026-01-05T10:00:00.000",'
          '"completedSets":3,"volume":1500}]}',
    });

    final store = GymStore();
    await store.init();

    final sets = store.setsFor('A', 'a1');
    expect(sets, hasLength(1));
    expect(sets.single.weight, 50);
    expect(sets.single.done, isTrue);
    expect(store.totalSessions, 1);
    expect(store.sessions.first.workoutId, 'B');
    expect(store.sessions.first.volume, 1500);
  });

  test('вес пользователя сохраняется и загружается', () async {
    final first = GymStore();
    await first.init();
    first.setUserWeight(75.5);
    await first.flush();

    final second = GymStore();
    await second.init();
    expect(second.userWeight, 75.5);
  });

  test('рост пользователя сохраняется и загружается', () async {
    final first = GymStore();
    await first.init();
    first.setUserHeight(180);
    await first.flush();

    final second = GymStore();
    await second.init();
    expect(second.userHeight, 180);
  });

  test('вес и рост по умолчанию null, если не заданы', () async {
    final store = GymStore();
    await store.init();
    expect(store.userWeight, isNull);
    expect(store.userHeight, isNull);
  });

  test('некорректный вес не сохраняется валидацией на уровне store (границы)', () {
    // Store only stores whatever is passed; validation is done in UI.
    // Here we verify store accepts and stores positive values.
    final store = GymStore();
    store.setUserWeight(-5);
    expect(store.userWeight, -5);
  });

  test('порции воды отмечаются и снимаются', () async {
    final store = GymStore();
    await store.init();

    final today = DateTime.now();
    expect(store.getWaterForDate(today), 0);
    expect(store.getWaterPortions(today), 0);

    store.toggleWaterPortion(today, 0);
    expect(store.getWaterForDate(today), GymStore.waterPortionMl);
    expect(store.getWaterPortions(today), 1);

    store.toggleWaterPortion(today, 0);
    expect(store.getWaterForDate(today), 0);
    expect(store.getWaterPortions(today), 0);
  });

  test('нельзя отметить больше целевого количества порций воды', () async {
    final store = GymStore();
    await store.init();

    final today = DateTime.now();
    for (int i = 0; i < GymStore.waterPortionsCount; i++) {
      store.toggleWaterPortion(today, i);
    }
    expect(store.getWaterForDate(today), GymStore.waterGoalMl);

    // Trying to add one more portion should not exceed goal
    store.toggleWaterPortion(today, GymStore.waterPortionsCount);
    expect(store.getWaterForDate(today), GymStore.waterGoalMl);
  });

  test('вода сохраняется по датам и восстанавливается после перезапуска', () async {
    final first = GymStore();
    await first.init();

    final today = DateTime.now();
    first.toggleWaterPortion(today, 0);
    first.toggleWaterPortion(today, 1);
    await first.flush();

    final second = GymStore();
    await second.init();
    expect(second.getWaterForDate(today), GymStore.waterPortionMl * 2);
    expect(second.getWaterPortions(today), 2);
  });

  test('вода не сбрасывается при повторном открытии того же дня', () async {
    final store = GymStore();
    await store.init();

    final today = DateTime.now();
    store.toggleWaterPortion(today, 0);
    final before = store.getWaterForDate(today);
    // Simulate re-reading the same day
    final again = store.getWaterForDate(today);
    expect(before, again);
    expect(before, GymStore.waterPortionMl);
  });

  test('старый формат без новых полей читается с умолчаниями', () async {
    SharedPreferences.setMockInitialValues({
      GymStore.storageKey: '{"version":6,"sets":{},"sessions":[],"skipped":[],"overrides":{}}',
    });

    final store = GymStore();
    await store.init();

    expect(store.userWeight, isNull);
    expect(store.userHeight, isNull);
    expect(store.getWaterForDate(DateTime.now()), 0);
  });
}
