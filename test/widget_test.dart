import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'экран "Сегодня" показывает три карточки: Вторник, Четверг, Суббота',
    (tester) async {
      await tester.pumpWidget(const GymLogApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Каждый день недели встречается как минимум один раз (в карточке)
      expect(find.text('Вторник'), findsAtLeast(1));
      expect(find.text('Четверг'), findsAtLeast(1));
      expect(find.text('Суббота'), findsAtLeast(1));

      // Удалённые элементы отсутствуют
      expect(find.text('ТВОЙ ДЕНЬ'), findsNothing);
      expect(find.text('МОИ ТРЕНИРОВКИ'), findsNothing);
      expect(find.textContaining('За последние 7 дней'), findsNothing);
    },
  );

  testWidgets('карточки открывают правильные тренировки', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Нажимаем на первую карточку (Вторник)
    await tester.tap(find.text('Вторник').first);
    await tester.pumpAndSettle();
    expect(find.text('Тренировка A'), findsOneWidget);
  });

  testWidgets(
    'экран "Статистика" не содержит секций по упражнениям и тренировкам',
    (tester) async {
      await tester.pumpWidget(const GymLogApp());
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();
      expect(find.text('АНАЛИТИКА'), findsOneWidget);

      expect(find.text('ПО УПРАЖНЕНИЯМ'), findsNothing);
      expect(find.text('ПО ТРЕНИРОВКАМ'), findsNothing);
    },
  );

  testWidgets('экран "Настройки" не содержит архива и локального хранилища', (
    tester,
  ) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки').first);
    await tester.pumpAndSettle();

    // Крупный заголовок «Настройки» (35pt) присутствует
    expect(find.text('Настройки'), findsAtLeast(1));

    expect(find.text('Архив прогресса'), findsNothing);
    expect(find.text('Локальное хранилище'), findsNothing);

    expect(find.text('Резервная копия'), findsOneWidget);
    expect(find.text('Импорт копии'), findsOneWidget);
    expect(find.text('Очистить всё'), findsOneWidget);
  });

  testWidgets('резервное копирование, импорт и очистка доступны', (
    tester,
  ) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки').first);
    await tester.pumpAndSettle();

    expect(find.text('Резервная копия'), findsOneWidget);
    expect(find.text('Импорт копии'), findsOneWidget);
    expect(find.text('Очистить всё'), findsOneWidget);
  });

  testWidgets('главный экран показывает блоки веса и роста', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('МОЙ ВЕС'), findsOneWidget);
    expect(find.text('МОЙ РОСТ'), findsOneWidget);
  });

  testWidgets('главный экран показывает трекер воды', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('ВОДА'), findsOneWidget);
    expect(find.text('0 / 3000 мл'), findsOneWidget);
    expect(find.text('0 / 15 порций'), findsOneWidget);
  });

  testWidgets('нажатие на кружок воды обновляет UI сразу', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('0 / 3000 мл'), findsOneWidget);
    expect(find.text('0 / 15 порций'), findsOneWidget);

    final firstPortion = find.byKey(const ValueKey('water-portion-0'));
    expect(firstPortion, findsOneWidget);

    await tester.tap(firstPortion);
    await tester.pumpAndSettle();

    expect(find.text('200 / 3000 мл'), findsOneWidget);
    expect(find.text('1 / 15 порций'), findsOneWidget);

    final checkIcon = find.descendant(
      of: firstPortion,
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(checkIcon, findsOneWidget);
  });

  testWidgets('повторное нажатие на кружок воды снимает отметку', (
    tester,
  ) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final firstPortion = find.byKey(const ValueKey('water-portion-0'));

    await tester.tap(firstPortion);
    await tester.pumpAndSettle();
    expect(find.text('200 / 3000 мл'), findsOneWidget);

    await tester.tap(firstPortion);
    await tester.pumpAndSettle();

    expect(find.text('0 / 3000 мл'), findsOneWidget);
    expect(find.text('0 / 15 порций'), findsOneWidget);
  });

  testWidgets('нажатие на несколько кружков воды обновляет прогресс', (
    tester,
  ) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('water-portion-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('water-portion-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('water-portion-2')));
    await tester.pumpAndSettle();

    expect(find.text('600 / 3000 мл'), findsOneWidget);
    expect(find.text('3 / 15 порций'), findsOneWidget);

    final checkIcon0 = find.descendant(
      of: find.byKey(const ValueKey('water-portion-0')),
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(checkIcon0, findsOneWidget);

    final checkIcon1 = find.descendant(
      of: find.byKey(const ValueKey('water-portion-1')),
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(checkIcon1, findsOneWidget);

    final checkIcon2 = find.descendant(
      of: find.byKey(const ValueKey('water-portion-2')),
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(checkIcon2, findsOneWidget);
  });

  testWidgets('кнопка сброса тренировки на экране тренировки', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Вторник').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('СОХРАНИТЬ'), 50);
    await tester.pumpAndSettle();

    expect(find.text('СБРОСИТЬ'), findsOneWidget);
    expect(find.text('СОХРАНИТЬ'), findsOneWidget);
  });

  testWidgets('изменение веса на главном экране сразу обновляет UI', (
    tester,
  ) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('МОЙ ВЕС'), findsOneWidget);
    expect(find.text('Не указан'), findsNWidgets(2));

    await tester.tap(find.text('МОЙ ВЕС').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '80');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить').first);
    await tester.pumpAndSettle();

    expect(find.text('80 кг'), findsOneWidget);
  });
}
