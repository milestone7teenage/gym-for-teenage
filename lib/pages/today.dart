import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
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
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 16),
          sliver: SliverToBoxAdapter(child: _UserMetricsRow()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(child: _WaterTracker()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User metrics: weight and height
// ---------------------------------------------------------------------------

class _UserMetricsRow extends StatelessWidget {
  const _UserMetricsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'МОЙ ВЕС',
            value: store.userWeight,
            format: (v) => '${_fmt(v)} кг',
            unit: 'килограмм',
            onTap: () => _editMetric(context, isWeight: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'МОЙ РОСТ',
            value: store.userHeight,
            format: (v) => '${v.toInt()} см',
            unit: 'сантиметров',
            onTap: () => _editMetric(context, isWeight: false),
          ),
        ),
      ],
    );
  }

  void _editMetric(BuildContext context, {required bool isWeight}) {
    final currentValue = isWeight ? store.userWeight : store.userHeight;
    final controller = TextEditingController(
      text: currentValue != null ? currentValue.toString() : '',
    );
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: panel,
          title: Text(
            isWeight ? 'Мой вес' : 'Мой рост',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Form(
            key: key,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      hintText:
                          isWeight ? 'Введите вес' : 'Введите рост',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: panel2,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      errorStyle: const TextStyle(fontSize: 11),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: const BorderSide(color: red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: const BorderSide(color: red),
                      ),
                    ),
                    validator: (value) {
                      final input = (value ?? '').trim().replaceAll(',', '.');
                      if (input.isEmpty) return 'Введите значение';
                      final parsed = double.tryParse(input);
                      if (parsed == null || parsed <= 0) {
                        return 'Введите число больше нуля';
                      }
                      if (isWeight) {
                        if (parsed < 30 || parsed > 300) {
                          return 'Вес должен быть от 30 до 300 кг';
                        }
                      } else {
                        if (parsed < 50 || parsed > 250) {
                          return 'Рост должен быть от 50 до 250 см';
                        }
                      }
                      return null;
                    },
                    onEditingComplete: () => _saveMetric(
                        dialogContext, key, isWeight, setDialogState),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWeight
                        ? 'Вес в килограммах'
                        : 'Рост в сантиметрах',
                    style: const TextStyle(
                        color: textMuted, fontSize: 11, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => _saveMetric(
                  dialogContext, key, isWeight, setDialogState),
              style: FilledButton.styleFrom(backgroundColor: purple),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMetric(BuildContext dialogContext, GlobalKey<FormState> key,
      bool isWeight, StateSetter setDialogState) async {
    final form = key.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    final field = form.fields.first;
    final input =
        field.value?.toString().trim().replaceAll(',', '.') ?? '';
    final parsed = double.tryParse(input);
    if (parsed == null) return;
    if (isWeight) {
      store.setUserWeight(parsed);
    } else {
      store.setUserHeight(parsed);
    }
    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double? value;
  final String Function(double) format;
  final String unit;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.format,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                value != null ? format(value!) : 'Не указан',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: value != null ? Colors.white : textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unit,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Workout card
// ---------------------------------------------------------------------------

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutCard({required this.workout, required this.onTap});

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
                  workout.day,
                  style: const TextStyle(
                    color: purpleSoft,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  workout.day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
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

// ---------------------------------------------------------------------------
// Water tracker
// ---------------------------------------------------------------------------

class _WaterTracker extends StatelessWidget {
  const _WaterTracker();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final consumedMl = store.getWaterForDate(today);
    final portions = store.getWaterPortions(today);
    const goal = GymStore.waterGoalMl;
    const portionsCount = GymStore.waterPortionsCount;

    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                  Icons.water_drop_rounded, color: purpleSoft, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ВОДА',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              Text(
                '$portions / $portionsCount порций',
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$consumedMl / $goal мл',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(portionsCount, (index) {
              final filled = index < portions;
              return GestureDetector(
                key: ValueKey('water-portion-$index'),
                behavior: HitTestBehavior.opaque,
                onTap: () => store.toggleWaterPortion(today, index),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? purple : Colors.transparent,
                    border: Border.all(
                      color: filled ? purple : border,
                      width: 2,
                    ),
                  ),
                  child: filled
                      ? const Icon(
                          Icons.check_rounded, color: Colors.white, size: 22)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}