import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

// ---------------------------------------------------------------------------
// Тренировка
// ---------------------------------------------------------------------------

class WorkoutPage extends StatelessWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final completed = store.completedSets(workout);
    final total = store.totalSets(workout);
    final progress = total == 0 ? 0.0 : completed / total;
    final exercises = store.exercisesOf(workout);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          workout.name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF241D43), Color(0xFF10121A)],
              ),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: const Color(0xFF3A315D)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: const Color(0xFF352E4D),
                        color: purpleSoft,
                      ),
                      Center(
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.day.toUpperCase(),
                        style: const TextStyle(
                          color: purpleSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$completed из $total подходов',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Открывай упражнение и записывай веса.',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          for (var index = 0; index < exercises.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ExerciseListRow(
                number: index + 1,
                exercise: exercises[index],
                skipped: store.isSkipped(workout, exercises[index]),
                replaced: store.hasReplacement(workout, index),
                done: store
                    .setsFor(workout.id, exercises[index].id)
                    .where((s) => s.done)
                    .length,
                total: store.setsFor(workout.id, exercises[index].id).length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExercisePage(
                      workout: workout,
                      exercise: exercises[index],
                      index: index,
                    ),
                  ),
                ),
                onSkip: () {
                  store.setSkipped(workout, exercises[index], true);
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        content: Text('${exercises[index].name} — пропущено'),
                        action: SnackBarAction(
                          label: 'ВЕРНУТЬ',
                          onPressed: () =>
                              store.setSkipped(workout, exercises[index], false),
                        ),
                      ),
                    );
                },
                onUnskip: () =>
                    store.setSkipped(workout, exercises[index], false),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: completed == 0
                ? null
                : () {
                    store.saveSession(workout);
                    Navigator.pop(context);
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: purple,
              disabledBackgroundColor: panel2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'СОХРАНИТЬ ТРЕНИРОВКУ',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseListRow extends StatelessWidget {
  final int number;
  final Exercise exercise;
  final bool skipped;
  final bool replaced;
  final int done;
  final int total;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final VoidCallback onUnskip;

  const _ExerciseListRow({
    required this.number,
    required this.exercise,
    required this.skipped,
    required this.replaced,
    required this.done,
    required this.total,
    required this.onTap,
    required this.onSkip,
    required this.onUnskip,
  });

  @override
  Widget build(BuildContext context) {
    final complete = done == total && total > 0 && !skipped;
    return Dismissible(
      key: ValueKey('skip-${exercise.id}-$number'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (skipped) return false;
        onSkip();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2B202C),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.skip_next_rounded, color: red),
      ),
      child: Opacity(
        opacity: skipped ? .55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: complete
                      ? const Color(0xFF31543A)
                      : skipped
                          ? const Color(0xFF3A2C30)
                          : border,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '$number',
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ExerciseImage(exercise: exercise, size: 57),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            decoration:
                                skipped ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skipped
                              ? '${exercise.muscle} • пропущено'
                              : '${exercise.muscle} • $done/$total подхода',
                          style: TextStyle(
                            color: skipped ? red : textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (replaced) ...[
                          const SizedBox(height: 3),
                          const Text(
                            'заменено',
                            style: TextStyle(
                              color: purpleSoft,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (skipped)
                    TextButton(
                      onPressed: onUnskip,
                      child: const Text(
                        'ВЕРНУТЬ',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                        ),
                      ),
                    )
                  else
                    Icon(
                      complete
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: complete ? green : textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Упражнение
// ---------------------------------------------------------------------------

class ExercisePage extends StatefulWidget {
  final Workout workout;
  final Exercise exercise;
  final int index;

  const ExercisePage({
    super.key,
    required this.workout,
    required this.exercise,
    required this.index,
  });

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late List<TextEditingController> _weights;
  late List<TextEditingController> _reps;
  late List<TextEditingController> _notes;
  final List<bool> _noteOpen = [];

  @override
  void initState() {
    super.initState();
    _makeControllers();
  }

  void _makeControllers() {
    final sets = store.setsFor(widget.workout.id, widget.exercise.id);
    _weights = [
      for (final s in sets) TextEditingController(text: _fmt(s.weight))
    ];
    _reps = [
      for (final s in sets) TextEditingController(text: '${s.reps}')
    ];
    _notes = [
      for (final s in sets) TextEditingController(text: s.note)
    ];
    _noteOpen
      ..clear()
      ..addAll([
        for (final s in sets) s.note.isNotEmpty,
      ]);
  }

  String _fmt(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  void _syncControllers() {
    final sets = store.setsFor(widget.workout.id, widget.exercise.id);
    while (_weights.length < sets.length) {
      final i = _weights.length;
      _weights.add(TextEditingController(text: _fmt(sets[i].weight)));
      _reps.add(TextEditingController(text: '${sets[i].reps}'));
      _notes.add(TextEditingController(text: sets[i].note));
      _noteOpen.add(sets[i].note.isNotEmpty);
    }
  }

  @override
  void dispose() {
    for (final c in _weights) {
      c.dispose();
    }
    for (final c in _reps) {
      c.dispose();
    }
    for (final c in _notes) {
      c.dispose();
    }
    super.dispose();
  }

  SessionExercise? get _lastSession {
    for (final session in store.sessions) {
      for (final e in session.exercises) {
        if (e.exerciseId == widget.exercise.id && e.sets.isNotEmpty) {
          return e;
        }
      }
    }
    return null;
  }

  void _openSheet(Widget child) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();
    final sets = store.setsFor(widget.workout.id, widget.exercise.id);
    final exercises = store.exercisesOf(widget.workout);
    final idx = widget.index < exercises.length ? widget.index : 0;
    final done = sets.where((s) => s.done).length;
    final last = _lastSession;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          widget.exercise.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 34),
        children: [
          Hero(
            tag: 'exercise-${widget.exercise.id}',
            child: ExerciseHeroImage(exercise: widget.exercise),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.menu_book_rounded,
                  label: 'ТЕХНИКА',
                  onTap: () => _openSheet(
                    TechniqueSheet(exercise: widget.exercise),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: Icons.history_rounded,
                  label: 'ИСТОРИЯ',
                  onTap: () => _openSheet(
                    ExerciseHistorySheet(
                      workout: widget.workout,
                      exercise: widget.exercise,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: Icons.swap_horiz_rounded,
                  label: 'ЗАМЕНИТЬ',
                  onTap: () => _openSheet(
                    ReplaceSheet(
                      workout: widget.workout,
                      index: idx,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ПОДХОДЫ',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$done / ${sets.length}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LastSessionCard(last: last),
          const SizedBox(height: 14),
          for (var index = 0; index < sets.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: SetRow(
                number: index + 1,
                set: sets[index],
                weight: _weights[index],
                reps: _reps[index],
                note: _notes[index],
                noteOpen: _noteOpen[index],
                onToggleNote: () =>
                    setState(() => _noteOpen[index] = !_noteOpen[index]),
                onDone: () {
                  store.toggleDone(
                      widget.workout.id, widget.exercise.id, index);
                  setState(() {});
                },
                onWeightChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed != null) {
                    store.updateWeight(
                      widget.workout.id,
                      widget.exercise.id,
                      index,
                      parsed,
                    );
                  }
                },
                onRepsChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    store.updateReps(
                      widget.workout.id,
                      widget.exercise.id,
                      index,
                      parsed,
                    );
                  }
                },
                onNoteChanged: (value) => store.updateNote(
                  widget.workout.id,
                  widget.exercise.id,
                  index,
                  value,
                ),
                onDelete: () {
                  if (sets.length <= 1) return;
                  store.removeSet(
                    widget.workout.id,
                    widget.exercise.id,
                    index,
                  );
                  final w = _weights.removeAt(index);
                  final r = _reps.removeAt(index);
                  final n = _notes.removeAt(index);
                  w.dispose();
                  r.dispose();
                  n.dispose();
                  _noteOpen.removeAt(index);
                  setState(() {});
                },
              ),
            ),
          OutlinedButton.icon(
            onPressed: () {
              store.addSet(widget.workout.id, widget.exercise.id);
              _syncControllers();
              setState(() {});
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('ЕЩЁ ПОДХОД'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(53),
              side: const BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: .7,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _ExerciseSwitchButton(
                  label: 'НАЗАД',
                  icon: Icons.arrow_back_rounded,
                  enabled: idx > 0,
                  onTap: idx > 0
                      ? () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExercisePage(
                                workout: widget.workout,
                                exercise: exercises[idx - 1],
                                index: idx - 1,
                              ),
                            ),
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ExerciseSwitchButton(
                  label: 'ДАЛЬШЕ',
                  icon: Icons.arrow_forward_rounded,
                  enabled: idx < exercises.length - 1,
                  filled: true,
                  onTap: idx < exercises.length - 1
                      ? () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExercisePage(
                                workout: widget.workout,
                                exercise: exercises[idx + 1],
                                index: idx + 1,
                              ),
                            ),
                          )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: purpleSoft),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  final SessionExercise? last;

  const _LastSessionCard({required this.last});

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    SessionRecord? record;
    if (last != null) {
      for (final s in store.sessions) {
        if (s.exercises.any((e) => e.exerciseId == last!.exerciseId)) {
          record = s;
          break;
        }
      }
    }

    final children = <Widget>[
      const Icon(Icons.history_rounded, size: 17, color: purpleSoft),
      const SizedBox(width: 8),
      const Text(
        'ПРОШЛЫЙ РАЗ',
        style: TextStyle(
          color: purpleSoft,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      const Spacer(),
    ];

    if (last == null || record == null) {
      children.add(
        const Text(
          'Первая запись',
          style: TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      children.addAll([
        Text(
          '${_date(record.date)} • ${last!.sets.map((s) => '${_fmt(s.weight)}×${s.reps}').join(', ')}',
          style: const TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF17142A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F2850)),
      ),
      child: Row(
        children: children,
      ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}

// ---------------------------------------------------------------------------
// Сет строка
// ---------------------------------------------------------------------------

class SetRow extends StatelessWidget {
  final int number;
  final SetEntry set;
  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController note;
  final bool noteOpen;
  final VoidCallback onDone;
  final VoidCallback onDelete;
  final VoidCallback onToggleNote;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<String> onNoteChanged;

  const SetRow({
    super.key,
    required this.number,
    required this.set,
    required this.weight,
    required this.reps,
    required this.note,
    required this.noteOpen,
    required this.onDone,
    required this.onDelete,
    required this.onToggleNote,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: set.done ? const Color(0xFF111D15) : panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: set.done ? const Color(0xFF31543A) : border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$number',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: NumericField(
                  controller: weight,
                  suffix: 'кг',
                  onChanged: onWeightChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: NumericField(
                  controller: reps,
                  suffix: 'раз',
                  onChanged: onRepsChanged,
                  integer: true,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Заметка',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onToggleNote,
                icon: Icon(
                  noteOpen || set.note.isNotEmpty
                      ? Icons.sticky_note_2_rounded
                      : Icons.sticky_note_2_outlined,
                  size: 18,
                  color: set.note.isNotEmpty ? purpleSoft : textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Удалить подход',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 19,
                  color: textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Готово',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
                onPressed: onDone,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: Container(
                    key: ValueKey(set.done),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: set.done ? green : Colors.transparent,
                      border: Border.all(
                        color: set.done ? green : textMuted,
                        width: 2.5,
                      ),
                    ),
                    child: set.done
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: noteOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextField(
                      controller: note,
                      onChanged: onNoteChanged,
                      maxLength: 140,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Заметка к подходу',
                        hintStyle: const TextStyle(
                          color: textMuted,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: textMuted,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 34,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: panel2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Отдых
// ---------------------------------------------------------------------------

class RestCard extends StatelessWidget {
  final int seconds;
  final int total;
  final bool paused;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onTogglePause;
  final VoidCallback onClose;

  const RestCard({
    super.key,
    required this.seconds,
    required this.total,
    required this.paused,
    required this.onMinus,
    required this.onPlus,
    required this.onTogglePause,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final sec = seconds % 60;
    final time = '$minutes:${sec.toString().padLeft(2, '0')}';
    final value = total <= 0 ? 0.0 : (seconds / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF241D43), Color(0xFF14151E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3A315D)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFF3A3160),
                  color: paused ? red : purpleSoft,
                ),
                Center(
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ОТДЫХ',
                  style: TextStyle(
                    color: purpleSoft,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  paused ? 'Пауза' : 'Идёт отсчёт',
                  style: TextStyle(
                    color: paused ? red : textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Минус 15 секунд',
            onPressed: onMinus,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
          IconButton(
            tooltip: paused ? 'Продолжить' : 'Пауза',
            onPressed: onTogglePause,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 24,
              color: purpleSoft,
            ),
          ),
          IconButton(
            tooltip: 'Плюс 15 секунд',
            onPressed: onPlus,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Закрыть таймер',
            onPressed: onClose,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSwitchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback? onTap;

  const _ExerciseSwitchButton({
    required this.label,
    required this.icon,
    required this.enabled,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return filled
        ? FilledButton.icon(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: Colors.white,
              side: const BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          );
  }
}

// ---------------------------------------------------------------------------
// Шторки: техника, история, замена
// ---------------------------------------------------------------------------

class TechniqueSheet extends StatelessWidget {
  final Exercise exercise;

  const TechniqueSheet({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              exercise.muscle.toUpperCase(),
              style: const TextStyle(
                color: purpleSoft,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: panel2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: purpleSoft),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exercise.technique,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseHistorySheet extends StatelessWidget {
  final Workout workout;
  final Exercise exercise;

  const ExerciseHistorySheet({
    super.key,
    required this.workout,
    required this.exercise,
  });

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final current = store.setsFor(workout.id, exercise.id);
    final history = <(DateTime, List<SetRecord>)>[];
    for (final session in store.sessions) {
      for (final e in session.exercises) {
        if (e.exerciseId == exercise.id && e.sets.isNotEmpty) {
          history.add((session.date, e.sets));
          break;
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              const Text(
                'СЕЙЧАС В ТРЕНИРОВКЕ',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: panel2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < current.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              'Подход ${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              current[i].done
                                  ? '${_fmt(current[i].weight)} кг × ${current[i].reps}'
                                  : 'не отмечен',
                              style: TextStyle(
                                color: current[i].done ? green : textMuted,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'СОХРАНЁННЫЕ ТРЕНИРОВКИ',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Пока пусто. Сохрани тренировку — здесь появятся подходы.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ...history.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: panel2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _date(entry.$1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.$2
                              .map((s) => '${_fmt(s.weight)} кг × ${s.reps}')
                              .join('  •  '),
                          style: const TextStyle(
                            color: purpleSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class ReplaceSheet extends StatelessWidget {
  final Workout workout;
  final int index;

  const ReplaceSheet({super.key, required this.workout, required this.index});

  @override
  Widget build(BuildContext context) {
    final current = store.exerciseAt(workout, index);
    final options =
        exerciseLibrary.where((e) => e.id != current.id).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ЗАМЕНИТЬ УПРАЖНЕНИЕ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textMuted,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final option = options[i];
                  return ListTile(
                    onTap: () {
                      store.replaceExercise(workout, index, option);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    tileColor: panel2,
                    leading: ExerciseImage(exercise: option, size: 44),
                    title: Text(
                      option.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      option.muscle,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.swap_horiz_rounded,
                      color: purpleSoft,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            if (store.hasReplacement(workout, index)) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    store.resetReplacement(workout, index);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'ВЕРНУТЬ ИСХОДНОЕ УПРАЖНЕНИЕ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

