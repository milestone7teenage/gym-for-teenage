import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('сплэш сменяется главным экраном', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('ТВОЙ ДЕНЬ'), findsOneWidget);
    expect(find.text('МОИ ТРЕНИРОВКИ'), findsOneWidget);
  });

  testWidgets('нижняя навигация переключает вкладки', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Прогресс'));
    await tester.pumpAndSettle();
    expect(find.text('ПРОГРЕСС'), findsOneWidget);

    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();
    expect(find.text('АНАЛИТИКА'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.text('Приложение'), findsOneWidget);
  });

  testWidgets('тренировка открывается из списка', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Тренировка A').first);
    await tester.pumpAndSettle();

    expect(find.text('Бабочка'), findsOneWidget);
    expect(find.textContaining('подходов'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('СОХРАНИТЬ ТРЕНИРОВКУ'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('СОХРАНИТЬ ТРЕНИРОВКУ'), findsOneWidget);
  });

  testWidgets('отметка подхода запускает таймер отдыха', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Тренировка A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Бабочка').first);
    await tester.pumpAndSettle();

    expect(find.text('ТЕХНИКА'), findsOneWidget);
    expect(find.text('ИСТОРИЯ'), findsOneWidget);
    expect(find.text('ЗАМЕНИТЬ'), findsOneWidget);

    await tester.tap(find.byTooltip('Готово').first);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(
      find.text('ОТДЫХ'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ОТДЫХ'), findsOneWidget);
    expect(find.text('ЕЩЁ ПОДХОД'), findsOneWidget);

    await tester.tap(find.byTooltip('Пауза'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Пауза'), findsOneWidget);

    await tester.tap(find.byTooltip('Закрыть таймер'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('техника открывается в шторке', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Тренировка A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бабочка').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ТЕХНИКА'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Прижми спину'), findsOneWidget);
    expect(find.text('ТЕХНИКА'), findsOneWidget);
  });

  testWidgets('сохранённая тренировка попадает в прогресс и статистику',
      (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Тренировка A').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Бабочка').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Готово').first);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('СОХРАНИТЬ ТРЕНИРОВКУ'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('СОХРАНИТЬ ТРЕНИРОВКУ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('СОХРАНИТЬ ТРЕНИРОВКУ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Прогресс'));
    await tester.pumpAndSettle();
    expect(find.text('ПРОГРЕСС'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ПОСЛЕДНЯЯ ТРЕНИРОВКА'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Бабочка'), findsWidgets);

    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();
    expect(find.text('АНАЛИТИКА'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ПО УПРАЖНЕНИЯМ'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Бабочка'), findsWidgets);
  });
}
