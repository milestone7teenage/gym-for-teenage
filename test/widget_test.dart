import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('экран "Сегодня" показывает три карточки: Вторник, Четверг, Суббота',
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
  });

  testWidgets('карточки открывают правильные тренировки', (tester) async {
    await tester.pumpWidget(const GymLogApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Нажимаем на первую карточку (Вторник)
    await tester.tap(find.text('Вторник').first);
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

  testWidgets('резервное копирование, импорт и очистка доступны', (tester) async {
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

  }