import 'package:flutter/material.dart';

/// Упражнение. `id` — стабильный идентификатор слота в тренировке
/// (a1..c7) либо библиотечный идентификатор для подменяемых упражнений.
class Exercise {
  final String id;
  final String name;
  final String muscle;
  final String image;
  final IconData icon;
  final String technique;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.image,
    required this.icon,
    required this.technique,
  });
}

class Workout {
  final String id;
  final String name;
  final String day;
  final List<Exercise> exercises;

  const Workout(this.id, this.name, this.day, this.exercises);
}

/// Один записанный подход.
class SetEntry {
  double weight;
  int reps;
  bool done;
  String note;

  SetEntry({
    this.weight = 20,
    this.reps = 10,
    this.done = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
        'done': done,
        if (note.isNotEmpty) 'note': note,
      };

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        weight: (json['weight'] as num?)?.toDouble() ?? 20,
        reps: (json['reps'] as num?)?.toInt() ?? 10,
        done: json['done'] == true,
        note: json['note'] as String? ?? '',
      );
}

/// Снимок выполненного подхода внутри сохранённой тренировки.
class SetRecord {
  final double weight;
  final int reps;

  const SetRecord({required this.weight, required this.reps});

  Map<String, dynamic> toJson() => {'weight': weight, 'reps': reps};

  factory SetRecord.fromJson(Map<String, dynamic> json) => SetRecord(
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
      );
}

/// Снимок упражнения внутри сохранённой тренировки.
class SessionExercise {
  final String exerciseId;
  final String name;
  final String muscle;
  final List<SetRecord> sets;

  const SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.muscle,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'muscle': muscle,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory SessionExercise.fromJson(Map<String, dynamic> json) => SessionExercise(
        exerciseId: json['exerciseId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        muscle: json['muscle'] as String? ?? '',
        sets: ((json['sets'] as List<dynamic>?) ?? const [])
            .whereType<Map>()
            .map((e) => SetRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class SessionRecord {
  final String workoutId;
  final DateTime date;
  final int completedSets;
  final double volume;
  final List<SessionExercise> exercises;

  SessionRecord({
    required this.workoutId,
    required this.date,
    required this.completedSets,
    required this.volume,
    this.exercises = const [],
  });

  Map<String, dynamic> toJson() => {
        'workoutId': workoutId,
        'date': date.toIso8601String(),
        'completedSets': completedSets,
        'volume': volume,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        workoutId: json['workoutId'] as String? ?? 'A',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        completedSets: (json['completedSets'] as num?)?.toInt() ?? 0,
        volume: (json['volume'] as num?)?.toDouble() ?? 0,
        exercises: ((json['exercises'] as List<dynamic>?) ?? const [])
            .whereType<Map>()
            .map((e) => SessionExercise.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Библиотека упражнений — единственный источник правды по картинкам,
/// группам мышц и описанию техники. Используется в том числе
/// для функции «Заменить».
const butterfly = Exercise(
  id: 'butterfly',
  name: 'Бабочка',
  muscle: 'Грудь',
  image: 'assets/exercises/butterfly.jpg',
  icon: Icons.favorite_outline_rounded,
  technique:
      'Прижми спину и лопатки к спинке, взгляд вперёд. Своди рукояти перед грудью '
      'без рывка, задержись на секунду и возвращай медленно, чувствуя растяжение груди.',
);

const tbarRow = Exercise(
  id: 'tbarRow',
  name: 'Тяга Т-грифа',
  muscle: 'Спина',
  image: 'assets/exercises/tbar_row.gif',
  icon: Icons.fitness_center_rounded,
  technique:
      'Наклон корпуса около 45°, поясница с прогибом. Тяни гриф к животу за счёт '
      'сведения лопаток, локти веди вдоль корпуса. Корпусом не раскачивайся.',
);

const shoulderPress = Exercise(
  id: 'shoulderPress',
  name: 'Жим плеч',
  muscle: 'Плечи',
  image: 'assets/exercises/shoulder_press.jpg',
  icon: Icons.arrow_upward_rounded,
  technique:
      'Прижми спину к спинке, сведи лопатки. Жми вверх до почти полного выпрямления '
      'локтей, не прогибая поясницу. Опускай под контролем, до уровня ушей.',
);

const legCurl = Exercise(
  id: 'legCurl',
  name: 'Сгибание ног',
  muscle: 'Ноги',
  image: 'assets/exercises/leg_curl.gif',
  icon: Icons.directions_run_rounded,
  technique:
      'Лёжа на тренажёре, валик чуть выше щиколотки. Сгибай ноги до упора, '
      'задержись на секунду и опускай без рывка, не отрывая бёдра от скамьи.',
);

const legExtension = Exercise(
  id: 'legExtension',
  name: 'Разгибание ног',
  muscle: 'Ноги',
  image: 'assets/exercises/leg_extension.gif',
  icon: Icons.directions_run_rounded,
  technique:
      'Сядь глубже, валики на голени у щиколоток. Разгибай ноги до горизонтали, '
      'напрягая квадрицепс в верхней точке. Не замахивайся корпусом.',
);

const hammerCurl = Exercise(
  id: 'hammerCurl',
  name: 'Молотки',
  muscle: 'Бицепс',
  image: 'assets/exercises/hammer_curl.jpg',
  icon: Icons.fitness_center_rounded,
  technique:
      'Локти прижаты к корпусу, нейтральный хват — ладони смотрят друг на друга. '
      'Поднимай без раскачки, опускай медленно на две секунды.',
);

const tricepsBlock = Exercise(
  id: 'tricepsBlock',
  name: 'Трицепс в блоке',
  muscle: 'Трицепс',
  image: 'assets/exercises/triceps_block.png',
  icon: Icons.fitness_center_rounded,
  technique:
      'Локти зафиксированы у корпуса, спина прямая, лёгкий наклон вперёд. '
      'Выжимай рукоять вниз до полного выпрямления и возвращай под контролем.',
);

const hammerPress = Exercise(
  id: 'hammerPress',
  name: 'Жим в хаммере',
  muscle: 'Грудь',
  image: 'assets/exercises/hammer_press.gif',
  icon: Icons.fitness_center_rounded,
  technique:
      'Прижми спину и лопатки к спинке, хват по ширине плеч. Жми вперёд-вверх, '
      'не сводя рукояти резко, и возвращай с весом под контролем.',
);

const pullups = Exercise(
  id: 'pullups',
  name: 'Подтягивания',
  muscle: 'Спина',
  image: 'assets/exercises/pullups.jpg',
  icon: Icons.self_improvement_rounded,
  technique:
      'Вис на прямых руках, сведи лопатки. Тяни грудь к перекладине, локти веди '
      'вниз и в стороны. Опускайся полностью; при необходимости помогай резинкой.',
);

const lateralRaise = Exercise(
  id: 'lateralRaise',
  name: 'Махи на плечи',
  muscle: 'Плечи',
  image: 'assets/exercises/lateral_raise.jpg',
  icon: Icons.open_with_rounded,
  technique:
      'Лёгкий наклон корпуса вперёд, гантели у бёдер. Поднимай руки в стороны '
      'до уровня плеч, слегка согнув локти, и опускай медленно.',
);

const hackSquat = Exercise(
  id: 'hackSquat',
  name: 'Присед в гакке',
  muscle: 'Ноги',
  image: 'assets/exercises/hack_squat.jpg',
  icon: Icons.directions_run_rounded,
  technique:
      'Спина и голова на спинке, ноги на середине платформы. Приседай до угла '
      'около 90° в коленях, не заворачивая их внутрь, и выталкивай через пятки.',
);

const cableCurl = Exercise(
  id: 'cableCurl',
  name: 'Бицепс в блоке',
  muscle: 'Бицепс',
  image: 'assets/exercises/cable_curl.jpg',
  icon: Icons.fitness_center_rounded,
  technique:
      'Локти зафиксированы у корпуса, спина прямая. Сгибай руки до уровня плеч, '
      'сжимая бицепс в верхней точке, и возвращай без раскачки.',
);

const inclineDbPress = Exercise(
  id: 'inclineDbPress',
  name: 'Жим гантелей под градусом',
  muscle: 'Грудь',
  image: 'assets/exercises/incline_db_press.jpg',
  icon: Icons.fitness_center_rounded,
  technique:
      'Скамья под углом 30°. Опускай гантели до уровня груди, локти под 45° к '
      'корпусу, жми вверх, сводя чуть не сходясь. Поясницу не выгибай.',
);

const latPulldown = Exercise(
  id: 'latPulldown',
  name: 'Тяга вертикального блока',
  muscle: 'Спина',
  image: 'assets/exercises/lat_pulldown.gif',
  icon: Icons.fitness_center_rounded,
  technique:
      'Прижми бёдра к валикам, лёгкий отклонение корпуса назад. Тяни рукоять '
      'к верху груди за счёт лопаток и медленно возвращай вес.',
);

const seatedDbCurl = Exercise(
  id: 'seatedDbCurl',
  name: 'Бицепс гантелями сидя',
  muscle: 'Бицепс',
  image: 'assets/exercises/seated_db_curl.gif',
  icon: Icons.fitness_center_rounded,
  technique:
      'Сидя с прямой спиной, локти у корпуса. Поднимай гантели без раскачки, '
      'сводя в верхней точке, и опускай на две секунды.',
);

const exerciseLibrary = <Exercise>[
  butterfly,
  tbarRow,
  shoulderPress,
  legCurl,
  legExtension,
  hammerCurl,
  tricepsBlock,
  hammerPress,
  pullups,
  lateralRaise,
  hackSquat,
  cableCurl,
  inclineDbPress,
  latPulldown,
  seatedDbCurl,
];

final _libraryById = {for (final e in exerciseLibrary) e.id: e};

Exercise? libraryExercise(String id) => _libraryById[id];

/// Копия библиотечного упражнения с постоянным id слота: сохраняет
/// совместимость со старыми ключами хранилища (`A::a1` и т.п.).
Exercise _slot(String slotId, Exercise template) => Exercise(
      id: slotId,
      name: template.name,
      muscle: template.muscle,
      image: template.image,
      icon: template.icon,
      technique: template.technique,
    );

/// Тренировки: A — вторник, B — четверг, C — суббота.
final workouts = <Workout>[
  Workout('A', 'Тренировка A', 'Вторник', [
    _slot('a1', butterfly),
    _slot('a2', tbarRow),
    _slot('a3', shoulderPress),
    _slot('a4', legCurl),
    _slot('a5', legExtension),
    _slot('a6', hammerCurl),
    _slot('a7', tricepsBlock),
  ]),
  Workout('B', 'Тренировка B', 'Четверг', [
    _slot('b1', hammerPress),
    _slot('b2', pullups),
    _slot('b3', lateralRaise),
    _slot('b4', hackSquat),
    _slot('b5', cableCurl),
    _slot('b6', tricepsBlock),
  ]),
  Workout('C', 'Тренировка C', 'Суббота', [
    _slot('c1', inclineDbPress),
    _slot('c2', latPulldown),
    _slot('c3', shoulderPress),
    _slot('c4', legCurl),
    _slot('c5', legExtension),
    _slot('c6', seatedDbCurl),
    _slot('c7', tricepsBlock),
  ]),
];

Workout? workoutById(String id) {
  for (final w in workouts) {
    if (w.id == id) return w;
  }
  return null;
}
