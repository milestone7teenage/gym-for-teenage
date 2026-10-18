import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'workout.dart';

class HomePage extends StatelessWidget {
  final Workout today;

  const HomePage({super.key, required this.today});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 32),
          sliver: SliverList.separated(
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (_, index) {
              final workout = workouts[index];
              return _WorkoutCard(
                workout: workout,
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
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutCard({required this.workout, required this.onTap});

  String get _label {
    switch (workout.id) {
      case 'A':
        return '1';
      case 'B':
        return '2';
      case 'C':
        return '3';
      default:
        return workout.id;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _label,
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
                      workout.day,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}