import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final allSets = store.totalCompletedSets;
    final sessions = store.totalSessions;
    final volume = store.totalVolume;

    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    final weekAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    final twoWeeksAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 14));

    final last30 = store.sessionsSince(monthAgo);
    final perWeek = last30.isEmpty ? 0.0 : last30.length / 4.3;
    final volume7 = store.volumeSince(weekAgo);
    final volumePrev = store.volumeSince(twoWeeksAgo) - volume7;

    final recent = store.sessions.take(8).toList().reversed.toList();
    final maxRecent = recent.fold<double>(
      1,
      (m, s) => s.volume > m ? s.volume : m,
    );

    final best = _bestByExercise(store.sessions);
    final bestSession = sessions == 0
        ? null
        : store.sessions.fold<SessionRecord>(
            store.sessions.first,
            (a, b) => b.volume > a.volume ? b : a,
          );
    final perExercise = _byExercise(store.sessions);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 7),
          sliver: SliverToBoxAdapter(
            child: Text(
              'АНАЛИТИКА',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 19),
          sliver: SliverToBoxAdapter(child: ScreenTitle('Статистика')),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.45,
            children: [
              _StatCard(
                icon: Icons.fitness_center_rounded,
                value: '$allSets',
                label: 'ПОДХОДОВ',
              ),
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: '${volume.round()}',
                label: 'КГ ОБЪЁМА',
              ),
              _StatCard(
                icon: Icons.event_available_rounded,
                value: '$sessions',
                label: 'ТРЕНИРОВОК',
              ),
              _StatCard(
                icon: Icons.speed_rounded,
                value: sessions == 0
                    ? '—'
                    : '${(volume / sessions).round()}',
                label: 'КГ В СРЕДНЕМ',
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 19, 20, 9),
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(title: 'ЧАСТОТА'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _FrequencyCard(
              perWeek: perWeek,
              last30: last30.length,
              lastDate: store.sessions.isEmpty ? null : store.sessions.first.date,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 19, 20, 9),
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(title: 'ДИНАМИКА ПОСЛЕДНИХ ТРЕНИРОВОК'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _TrendCard(
              recent: recent,
              maxVolume: maxRecent,
              volume7: volume7,
              volumePrev: volumePrev,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 19, 20, 9),
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(title: 'ЛУЧШИЕ РЕЗУЛЬТАТЫ'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _PrCard(best: best, bestSession: bestSession),
          ),
        ),
        if (perExercise.isNotEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 19, 20, 9),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: 'ПО УПРАЖНЕНИЯМ'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: perExercise.take(8).length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (_, index) => _ExerciseRow(stat: perExercise[index]),
            ),
          ),
        ],
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 19, 20, 9),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(title: 'ПО ТРЕНИРОВКАМ'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          sliver: SliverList.separated(
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (_, index) {
              final workout = workouts[index];
              final count =
                  store.sessions.where((s) => s.workoutId == workout.id).length;
              final vol = store.sessions
                  .where((s) => s.workoutId == workout.id)
                  .fold<double>(0, (v, s) => v + s.volume);
              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF241D40),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        workout.id,
                        style: const TextStyle(
                          color: purpleSoft,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$count раз • ${vol.round()} кг',
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      workout.day,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Лучший подход по каждому упражнению из сохранённых сессий.
  static List<(Exercise, SetRecord)> _bestByExercise(
    List<SessionRecord> sessions,
  ) {
    final best = <String, (Exercise, SetRecord)>{};
    final byId = <String, Exercise>{};
    for (final w in workouts) {
      for (final e in w.exercises) {
        byId[e.id] = e;
      }
    }
    for (final e in exerciseLibrary) {
      byId[e.id] = e;
    }

    for (final session in sessions.reversed) {
      for (final se in session.exercises) {
        final exercise = byId[se.exerciseId];
        if (exercise == null) continue;
        for (final set in se.sets) {
          final current = best[se.exerciseId];
          final better = current == null ||
              set.weight > current.$2.weight ||
              (set.weight == current.$2.weight &&
                  set.reps > current.$2.reps);
          if (better) best[se.exerciseId] = (exercise, set);
        }
      }
    }

    final list = best.values.toList()
      ..sort((a, b) => b.$2.weight.compareTo(a.$2.weight));
    return list;
  }

  /// Агрегация по упражнениям: сколько раз встречалось, сколько подходов
  /// собрано и какой лучший подход записан.
  static List<_ExStat> _byExercise(List<SessionRecord> sessions) {
    final map = <String, _ExStat>{};
    for (final session in sessions) {
      for (final se in session.exercises) {
        final stat = map.putIfAbsent(
          se.exerciseId,
          () => _ExStat(se.name),
        );
        stat.sessions += 1;
        stat.sets += se.sets.length;
        for (final set in se.sets) {
          if (set.weight > stat.bestWeight ||
              (set.weight == stat.bestWeight && set.reps > stat.bestReps)) {
            stat.bestWeight = set.weight;
            stat.bestReps = set.reps;
          }
        }
      }
    }
    final list = map.values.toList()
      ..sort((a, b) {
        final bySets = b.sets.compareTo(a.sets);
        return bySets != 0 ? bySets : b.sessions.compareTo(a.sessions);
      });
    return list;
  }
}

class _ExStat {
  final String name;
  int sessions = 0;
  int sets = 0;
  double bestWeight = 0;
  int bestReps = 0;

  _ExStat(this.name);
}

class _ExerciseRow extends StatelessWidget {
  final _ExStat stat;

  const _ExerciseRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final best = stat.bestWeight % 1 == 0
        ? stat.bestWeight.toInt().toString()
        : stat.bestWeight.toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF241D40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: purpleSoft,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${stat.sessions} раз • ${stat.sets} подходов',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$best кг × ${stat.bestReps}',
            style: const TextStyle(
              color: purpleSoft,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyCard extends StatelessWidget {
  final double perWeek;
  final int last30;
  final DateTime? lastDate;

  const _FrequencyCard({
    required this.perWeek,
    required this.last30,
    required this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String ago = '—';
    if (lastDate != null) {
      final days = now.difference(lastDate!).inDays;
      ago = days == 0 ? 'сегодня' : days == 1 ? 'вчера' : '$days дн. назад';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Line(
              label: 'ТРЕНИРОВОК В НЕДЕЛЮ',
              value: perWeek == 0 ? '—' : perWeek.toStringAsFixed(1),
            ),
          ),
          Container(width: 1, height: 38, color: border),
          Expanded(
            child: _Line(label: 'ЗА 30 ДНЕЙ', value: '$last30'),
          ),
          Container(width: 1, height: 38, color: border),
          Expanded(
            child: _Line(label: 'ПОСЛЕДНЯЯ', value: ago),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: textMuted,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<SessionRecord> recent;
  final double maxVolume;
  final double volume7;
  final double volumePrev;

  const _TrendCard({
    required this.recent,
    required this.maxVolume,
    required this.volume7,
    required this.volumePrev,
  });

  @override
  Widget build(BuildContext context) {
    final trendUp = volume7 > volumePrev;
    final trendEqual = volume7 == volumePrev;

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
          Row(
            children: [
              const Text(
                'ОБЪЁМ ПО ТРЕНИРОВКАМ',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                trendEqual
                    ? 'БЕЗ ИЗМЕНЕНИЙ'
                    : trendUp
                        ? '↑ НЕДЕЛЯ К НЕДЕЛЕ'
                        : '↓ НЕДЕЛЯ К НЕДЕЛЕ',
                style: TextStyle(
                  color: trendEqual
                      ? textMuted
                      : trendUp
                          ? green
                          : red,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const Text(
              'Сохрани первую тренировку — здесь появится график.',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final s in recent)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Tooltip(
                          message: '${s.volume.round()} кг',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            height: 12 + 84 * (s.volume / maxVolume),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  purpleSoft,
                                  purple.withValues(alpha: .35),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'За 7 дней: ${volume7.round()} кг',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrCard extends StatelessWidget {
  final List<(Exercise, SetRecord)> best;
  final SessionRecord? bestSession;

  const _PrCard({required this.best, required this.bestSession});

  @override
  Widget build(BuildContext context) {
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
          if (best.isEmpty && bestSession == null)
            const Text(
              'Данные появятся после первой сохранённой тренировки.',
              style: TextStyle(
                color: textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (bestSession != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Лучший объём: ${bestSession!.volume.round()} кг',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...best.take(6).map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.$1.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_fmt(entry.$2.weight)} кг × ${entry.$2.reps}',
                        style: const TextStyle(
                          color: purpleSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: purpleSoft, size: 20),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 3),
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
      ),
    );
  }
}
