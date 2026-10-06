import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Локальное хранилище тренировок.
///
/// Ключ не менялся (`gym_log_v5`), поэтому данные, записанные старыми
/// версиями приложения, читаются как есть. Новые поля (`skipped`,
/// `overrides`, `settings`, `exercises` внутри сессий) добавлены как
/// необязательные — старые файлы загружаются с умолчениями.
class GymStore extends ChangeNotifier {
  static const storageKey = 'gym_log_v5';
  static const defaultSetsCount = 2;

  SharedPreferences? _prefs;
  final Map<String, List<SetEntry>> _sets = {};
  final List<SessionRecord> sessions = [];
  final Set<String> _skipped = {};
  final Map<String, String> _overrides = {};

  int restSeconds = 90;
  bool autoRest = true;
  bool haptics = true;

  Timer? _saveDebounce;
  Future<void> _pendingSave = Future<void>.value();
  bool ready = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _decode(raw);
      } catch (_) {
        // Повреждённый файл не должен ронять приложение: работаем с пустым
        // состоянием, а следующее сохранение перезапишет данные.
        _sets.clear();
        sessions.clear();
        _skipped.clear();
        _overrides.clear();
      }
    }
    ready = true;
    notifyListeners();
  }

  void _decode(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;

    final rawSets = root['sets'] as Map<String, dynamic>? ?? {};
    _sets.clear();
    for (final entry in rawSets.entries) {
      final list = (entry.value as List<dynamic>)
          .whereType<Map>()
          .map((e) => SetEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isNotEmpty) _sets[entry.key] = list;
    }

    final rawSessions = root['sessions'] as List<dynamic>? ?? [];
    sessions
      ..clear()
      ..addAll(rawSessions
          .whereType<Map>()
          .map((e) => SessionRecord.fromJson(Map<String, dynamic>.from(e))));

    _skipped
      ..clear()
      ..addAll(((root['skipped'] as List<dynamic>?) ?? const [])
          .whereType<String>());

    _overrides
      ..clear()
      ..addAll(((root['overrides'] as Map<String, dynamic>?) ?? const {})
          .map((k, v) => MapEntry(k, v.toString())));

    final settings = root['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      restSeconds = _clampRest((settings['rest'] as num?)?.toInt() ?? restSeconds);
      autoRest = settings['autoRest'] as bool? ?? autoRest;
      haptics = settings['haptics'] as bool? ?? haptics;
    }
  }

  static int _clampRest(int value) {
    if (value < 15) return 15;
    if (value > 600) return 600;
    return value;
  }

  String key(String workoutId, String exerciseId) => '$workoutId::$exerciseId';

  // ---------------------------------------------------------------- replacements

  Exercise exerciseAt(Workout workout, int index) {
    final replacement = _overrides['${workout.id}::$index'];
    if (replacement != null) {
      final library = libraryExercise(replacement);
      if (library != null) return library;
    }
    return workout.exercises[index];
  }

  List<Exercise> exercisesOf(Workout workout) =>
      List.generate(workout.exercises.length, (i) => exerciseAt(workout, i));

  bool hasReplacement(Workout workout, int index) =>
      _overrides.containsKey('${workout.id}::$index');

  void replaceExercise(Workout workout, int index, Exercise replacement) {
    if (index < 0 || index >= workout.exercises.length) return;
    final current = exerciseAt(workout, index);
    if (current.id == replacement.id) return;
    _overrides['${workout.id}::$index'] = replacement.id;
    _queueSave();
    notifyListeners();
  }

  void resetReplacement(Workout workout, int index) {
    if (_overrides.remove('${workout.id}::$index') != null) {
      _queueSave();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- skipped

  bool isSkipped(Workout workout, Exercise exercise) =>
      _skipped.contains(key(workout.id, exercise.id));

  void setSkipped(Workout workout, Exercise exercise, bool value) {
    final k = key(workout.id, exercise.id);
    final changed = value ? _skipped.add(k) : _skipped.remove(k);
    if (!changed) return;
    _queueSave();
    notifyListeners();
  }

  // ---------------------------------------------------------------- sets

  List<SetEntry> setsFor(String workoutId, String exerciseId) {
    return _sets.putIfAbsent(
      key(workoutId, exerciseId),
      () => List.generate(defaultSetsCount, (_) => SetEntry()),
    );
  }

  void updateWeight(String workoutId, String exerciseId, int index, double value) {
    setsFor(workoutId, exerciseId)[index].weight = value;
    _queueSave();
    notifyListeners();
  }

  void updateReps(String workoutId, String exerciseId, int index, int value) {
    setsFor(workoutId, exerciseId)[index].reps = value;
    _queueSave();
    notifyListeners();
  }

  void updateNote(String workoutId, String exerciseId, int index, String value) {
    setsFor(workoutId, exerciseId)[index].note = value;
    _queueSave();
    notifyListeners();
  }

  void toggleDone(String workoutId, String exerciseId, int index) {
    final set = setsFor(workoutId, exerciseId)[index];
    set.done = !set.done;
    _queueSave();
    notifyListeners();
  }

  void addSet(String workoutId, String exerciseId) {
    final sets = setsFor(workoutId, exerciseId);
    final last = sets.last;
    sets.add(SetEntry(weight: last.weight, reps: last.reps));
    _queueSave();
    notifyListeners();
  }

  void removeSet(String workoutId, String exerciseId, int index) {
    final sets = setsFor(workoutId, exerciseId);
    if (sets.length <= 1) return;
    sets.removeAt(index);
    _queueSave();
    notifyListeners();
  }

  // ---------------------------------------------------------------- totals

  int completedSets(Workout workout) => exercisesOf(workout).fold(
        0,
        (sum, e) => sum + setsFor(workout.id, e.id).where((s) => s.done).length,
      );

  int totalSets(Workout workout) => exercisesOf(workout).fold(
        0,
        (sum, e) => sum + setsFor(workout.id, e.id).length,
      );

  double volume(Workout workout) => exercisesOf(workout).fold<double>(
        0,
        (sum, e) =>
            sum +
            setsFor(workout.id, e.id)
                .where((s) => s.done)
                .fold<double>(0, (v, s) => v + s.weight * s.reps),
      );

  double get totalVolume => sessions.fold<double>(0, (v, s) => v + s.volume);

  int get totalCompletedSets =>
      sessions.fold<int>(0, (v, s) => v + s.completedSets);

  int get totalSessions => sessions.length;

  List<SessionRecord> sessionsSince(DateTime from) =>
      sessions.where((s) => s.date.isAfter(from)).toList();

  double volumeSince(DateTime from) =>
      sessionsSince(from).fold<double>(0, (v, s) => v + s.volume);

  // ---------------------------------------------------------------- sessions

  void saveSession(Workout workout) {
    final completed = completedSets(workout);
    if (completed == 0) return;

    final details = <SessionExercise>[];
    for (final exercise in exercisesOf(workout)) {
      final done =
          setsFor(workout.id, exercise.id).where((s) => s.done).toList();
      if (done.isEmpty) continue;
      details.add(SessionExercise(
        exerciseId: exercise.id,
        name: exercise.name,
        muscle: exercise.muscle,
        sets: [
          for (final s in done) SetRecord(weight: s.weight, reps: s.reps),
        ],
      ));
    }

    sessions.insert(
      0,
      SessionRecord(
        workoutId: workout.id,
        date: DateTime.now(),
        completedSets: completed,
        volume: volume(workout),
        exercises: details,
      ),
    );
    _queueSave(immediate: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------- settings

  void setRestSeconds(int value) {
    restSeconds = _clampRest(value);
    _queueSave();
    notifyListeners();
  }

  void setAutoRest(bool value) {
    autoRest = value;
    _queueSave();
    notifyListeners();
  }

  void setHaptics(bool value) {
    haptics = value;
    _queueSave();
    notifyListeners();
  }

  // ---------------------------------------------------------------- persistence

  Map<String, dynamic> _encode() => {
        'version': 6,
        'sets': {
          for (final entry in _sets.entries)
            entry.key: entry.value.map((e) => e.toJson()).toList(),
        },
        'sessions': sessions.map((e) => e.toJson()).toList(),
        'skipped': _skipped.toList(),
        'overrides': _overrides,
        'settings': {
          'rest': restSeconds,
          'autoRest': autoRest,
          'haptics': haptics,
        },
      };

  String exportJson() => jsonEncode(_encode());

  /// Импорт данных, скопированных из другого устройства.
  /// Возвращает false и ничего не меняет, если payload некорректен.
  bool importJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['sets'] is! Map && decoded['sessions'] is! List) return false;
      _decode(jsonEncode(decoded));
    } catch (_) {
      return false;
    }
    _queueSave(immediate: true);
    notifyListeners();
    return true;
  }

  void _queueSave({bool immediate = false}) {
    _saveDebounce?.cancel();
    if (immediate) {
      _enqueueSave();
      return;
    }
    _saveDebounce = Timer(const Duration(milliseconds: 350), _enqueueSave);
  }

  /// Сохраняет немедленно (вызывается при сворачивании приложения).
  Future<void> flush() async {
    _saveDebounce?.cancel();
    await _enqueueSave();
  }

  Future<void> _enqueueSave() {
    _pendingSave = _pendingSave
        .then((_) => _write())
        .catchError((Object _) {});
    return _pendingSave;
  }

  Future<void> _write() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(storageKey, jsonEncode(_encode()));
    } catch (_) {
      // Например, хранилище переполнено или недоступно — не роняем UI.
    }
  }

  Future<void> clearAll() async {
    _saveDebounce?.cancel();
    _sets.clear();
    sessions.clear();
    _skipped.clear();
    _overrides.clear();
    await _prefs?.remove(storageKey);
    notifyListeners();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}

final store = GymStore();
