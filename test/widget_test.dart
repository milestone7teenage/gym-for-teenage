import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('экран "Сегодня" показывает три карточки 1/2/3', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Три карточки с обозначениями 1/2/3
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);

    // Удалённые элементы отсутствуют
    expect(find.text('ТВОЙ ДЕНЬ'), findsNothing);
    expect(find.text('МОИ ТРЕНИРОВКИ'), findsNothing);
    expect(find.textContaining('За последние 7 дней'), findsNothing);
  });

  testWidgets('карточки открывают правильные тренировки', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(find.text('Тренировка A'), findsOneWidget);
  });

  testWidgets('экран "Статистика" не содержит секций по упражнениям и тренировкам',
      (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();
    expect(find.text('АНАЛИТИКА'), findsOneWidget);

    expect(find.text('ПО УПРАЖНЕНИЯМ'), findsNothing);
    expect(find.text('ПО ТРЕНИРОВКАМ'), findsNothing);
  });

  testWidgets('экран "Настройки" не содержит архива и локального хранилища',
      (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.text('Приложение'), findsOneWidget);

    expect(find.text('Архив прогресса'), findsNothing);
    expect(find.text('Локальное хранилище'), findsNothing);

    // Остались резервное копирование, импорт и очистка
    expect(find.text('Резервная копия'), findsOneWidget);
    expect(find.text('Импорт копии'), findsOneWidget);
    expect(find.text('Очистить всё'), findsOneWidget);
  });

  testWidgets('резервное копирование, импорт и очистка доступны', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    // Проверка, что кнопки присутствуют
    expect(find.text('Резервная копия'), findsOneWidget);
    expect(find.text('Импорт копии'), findsOneWidget);
    expect(find.text('Очистить всё'), findsOneWidget);
  });
}