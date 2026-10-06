import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'workout.dart';

class HomePage extends StatelessWidget {
  final Workout today;

  const HomePage({super.key, required this.today});

  String get dateLabel {
    const days = [
      'ПОНЕДЕЛЬНИК',
      'ВТОРНИК',
      'СРЕДА',
      'ЧЕТВЕРГ',
      'ПЯТНИЦА',
      'СУББОТА',
      'ВОСКРЕСЕНЬЕ'
    ];
    final d = DateTime.now();
    return '${days[d.weekday - 1]}, ${d.day} ${_month(d.month)}';
  }

  static String _month(int m) {
    const months = [
      '',
      'ЯНВАРЯ',
      'ФЕВРАЛЯ',
      'МАРТА',
      'АПРЕЛЯ',
      'МАЯ',
      'ИЮНЯ',
      'ИЮЛЯ',
      'АВГУСТА',
      'СЕНТЯБРЯ',
      'ОКТЯБРЯ',
      'НОЯБРЯ',
      'ДЕКАБРЯ'
    ];
    return months[m];
  }

  void pickWorkout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: panel,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const WorkoutPicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = store.completedSets(today);
    final total = store.totalSets(today);
    final progress = total == 0 ? 0.0 : completed / total;

    return CustomScrollView(
      key: const PageStorageKey('home'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: purpleSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ТВОЙ ДЕНЬ',
                  style: TextStyle(
                    fontSize: 37,
                    height: .95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.8,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Тренировка, записи подходов и отдых — в одном месте.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(child: _WeekStats(since: _week())),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(title: 'БЛИЖАЙШАЯ ТРЕНИРОВКА'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _TodayWorkoutCard(
              workout: today,
              completed: completed,
              total: total,
              progress: progress,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutPage(workout: today),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'МОИ ТРЕНИРОВКИ',
              trailing: TextButton.icon(
                onPressed: () => pickWorkout(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('ДОБАВИТЬ'),
                style: TextButton.styleFrom(
                  foregroundColor: purpleSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList.separated(
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (_, index) {
              final workout = workouts[index];
              final done = store.completedSets(workout);
              final totalSets = store.totalSets(workout);
              return _WorkoutListCard(
                workout: workout,
                done: done,
                total: totalSets,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutPage(workout: workout),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static DateTime _week() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
  }
}

/// Краткая статистика за последние 7 дней.
class _WeekStats extends StatelessWidget {
  final DateTime since;

  const _WeekStats({required this.since});

  @override
  Widget build(BuildContext context) {
    final recent = store.sessionsSince(since);
    final volume = store.volumeSince(since);
    final sets =
        recent.fold<int>(0, (sum, s) => sum + s.completedSets);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ЗА ПОСЛЕДНИЕ 7 ДНЕЙ',
            style: TextStyle(
              color: textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: '${recent.length}',
                  label: 'ТРЕНИРОВОК',
                ),
              ),
              Expanded(
                child: _Metric(
                  value: '${volume.round()}',
                  label: 'КГ ОБЪЁМА',
                ),
              ),
              Expanded(
                child: _Metric(value: '$sets', label: 'ПОДХОДОВ'),
              ),
              Expanded(
                child: _Metric(
                  value: '${store.totalSessions}',
                  label: 'ВСЕГО',
                ),
              ),
            ],
          ),
          if (store.totalSessions == 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Отметь выполненные подходы — статистика соберётся сама.',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
      ],
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  final Workout workout;
  final int completed;
  final int total;
  final double progress;
  final VoidCallback onTap;

  const _TodayWorkoutCard({
    required this.workout,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = store.exercisesOf(workout).length;
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF27204A), Color(0xFF11131B)],
              ),
              border: Border.all(color: const Color(0xFF3A315D)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
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
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            workout.name,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$exerciseCount упражнений • ${GymStore.defaultSetsCount} подхода по умолчанию',
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 65,
                      height: 65,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: const Color(0xFF352E4D),
                            color: purpleSoft,
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF312A46),
                    color: purple,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '$completed / $total подходов',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: purpleSoft,
                      size: 21,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutListCard extends StatelessWidget {
  final Workout workout;
  final int done;
  final int total;
  final VoidCallback onTap;

  const _WorkoutListCard({
    required this.workout,
    required this.done,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    final count = store.exercisesOf(workout).length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B38),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  workout.id,
                  style: const TextStyle(
                    color: purpleSoft,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workout.day} • $count упражнений',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (done > 0)
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(width: 7),
              const Icon(Icons.chevron_right_rounded, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutPicker extends StatelessWidget {
  const WorkoutPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
              child: Text(
                'ВЫБЕРИ ТРЕНИРОВКУ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: textMuted,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            ...workouts.map(
              (workout) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutPage(workout: workout),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: panel2,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF282143),
                    child: Text(
                      workout.id,
                      style: const TextStyle(
                        color: purpleSoft,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    workout.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${workout.day} • ${store.exercisesOf(workout).length} упражнений',
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
