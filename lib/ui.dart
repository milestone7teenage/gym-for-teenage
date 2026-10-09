import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme.dart';

/// Над-заголовок секции (капслок + мелкий кегль).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Крупный заголовок экрана.
class ScreenTitle extends StatelessWidget {
  final String text;

  const ScreenTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 35,
        height: 1,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.6,
      ),
    );
  }
}

/// Компактная превью-картинка упражнения.
class ExerciseImage extends StatelessWidget {
  final Exercise exercise;
  final double size;

  const ExerciseImage({
    super.key,
    required this.exercise,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .27),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          exercise.image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFF211D2F),
            alignment: Alignment.center,
            child: Icon(exercise.icon, color: purpleSoft, size: size * .38),
          ),
        ),
      ),
    );
  }
}

/// Картинка-герой на экране упражнения.
class ExerciseHeroImage extends StatelessWidget {
  final Exercise exercise;

  const ExerciseHeroImage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 230,
          decoration: const BoxDecoration(color: Color(0xFF151720)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                exercise.image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(exercise.icon, size: 70, color: purpleSoft),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                    stops: [.55, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.muscle.toUpperCase(),
                      style: const TextStyle(
                        color: purpleSoft,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Числовое поле ввода с единицами измерения.
class NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final bool integer;
  final ValueChanged<String> onChanged;
  final VoidCallback? onEditingComplete;

  const NumericField({
    super.key,
    required this.controller,
    required this.suffix,
    required this.onChanged,
    this.integer = false,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(integer ? r'[0-9]*' : r'[0-9.,]*'),
        ),
      ],
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      decoration: InputDecoration(
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      ),
    );
  }
}
