import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 7),
          sliver: SliverToBoxAdapter(
            child: Text(
              'ПРОГРЕСС',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
          sliver: SliverToBoxAdapter(child: ScreenTitle('Твоя история')),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _ArchiveHero(
              sessions: store.totalSessions,
              volume: store.totalVolume,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(title: 'ТРЕНИРОВКИ'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList.separated(
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (_, index) {
              final workout = workouts[index];
              final sessions = store.sessions
                  .where((s) => s.workoutId == workout.id)
                  .length;
              return _ProgressWorkoutCard(
                workout: workout,
                sessions: sessions,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutHistoryPage(workout: workout),
                  ),
                ),
              );
            },
          ),
        ),
        if (store.sessions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: _RecentSessionCard(record: store.sessions.first),
            ),
          ),
      ],
    );
  }
}

class _ArchiveHero extends StatelessWidget {
  final int sessions;
  final double volume;

  const _ArchiveHero({required this.sessions, required this.volume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF211A3A), Color(0xFF11131A)],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFF342A55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(value: '$sessions', label: 'ТРЕНИРОВОК'),
          ),
          Expanded(
            child: _Metric(value: '${volume.round()}', label: 'КГ ОБЪЁМА'),
          ),
          Expanded(
            child: _Metric(
              value: '${store.totalCompletedSets}',
              label: 'ПОДХОДОВ',
            ),
          ),
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
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _ProgressWorkoutCard extends StatelessWidget {
  final Workout workout;
  final int sessions;
  final VoidCallback onTap;

  const _ProgressWorkoutCard({
    required this.workout,
    required this.sessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF241D40),
                  borderRadius: BorderRadius.circular(16),
                ),
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
                      sessions == 0
                          ? 'Сохранённых тренировок пока нет'
                          : '$sessions сохранённых тренировок',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: purpleSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка последней сохранённой тренировки с детализацией подходов.
class _RecentSessionCard extends StatelessWidget {
  final SessionRecord record;

  const _RecentSessionCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final workout = workoutById(record.workoutId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'ПОСЛЕДНЯЯ ТРЕНИРОВКА',
            trailing: Text(
              _date(record.date),
              style: const TextStyle(
                color: purpleSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            workout?.name ?? 'Тренировка',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${record.completedSets} подходов • ${record.volume.round()} кг объёма',
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (record.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...record.exercises.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      e.sets
                          .map((s) => '${_fmt(s.weight)}×${s.reps}')
                          .join(' • '),
                      style: const TextStyle(
                        color: purpleSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class WorkoutHistoryPage extends StatelessWidget {
  final Workout workout;

  const WorkoutHistoryPage({super.key, required this.workout});

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  @override
  Widget build(BuildContext context) {
    final records =
        store.sessions.where((s) => s.workoutId == workout.id).toList();
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${workout.name} • архив',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: records.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Пока нет сохранённых тренировок.\n'
                  'Отметь подходы и нажми «Сохранить тренировку» — '
                  'записи появятся здесь.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (_, index) {
                final r = records[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: purpleSoft,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _date(r.date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${r.volume.round()} кг',
                            style: const TextStyle(
                              color: green,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.completedSets} подходов выполнено',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (r.exercises.isNotEmpty) ...[
                        const SizedBox(height: 11),
                        const Divider(height: 1, color: border),
                        const SizedBox(height: 9),
                        ...r.exercises.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  e.sets
                                      .map((s) => '${_fmt(s.weight)}×${s.reps}')
                                      .join(' • '),
                                  style: const TextStyle(
                                    color: purpleSoft,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}
