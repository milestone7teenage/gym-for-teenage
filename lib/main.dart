import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'pages/progress.dart';
import 'pages/settings.dart';
import 'pages/stats.dart';
import 'pages/today.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymLogApp());
}

class GymLogApp extends StatefulWidget {
  const GymLogApp({super.key});

  @override
  State<GymLogApp> createState() => _GymLogAppState();
}

class _GymLogAppState extends State<GymLogApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Последний шанс дописать отложенные изменения в хранилище.
    store.flush();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      store.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.ready) return const _Splash();
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Gym Log',
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: bg,
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              primary: purple,
              surface: panel,
            ),
            fontFamily: 'Segoe UI',
            fontFamilyFallback: const ['Arial', 'sans-serif'],
            splashFactory: NoSplash.splashFactory,
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: const FadeForwardsPageTransitionsBuilder(),
                TargetPlatform.linux: const FadeForwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
                TargetPlatform.fuchsia: const FadeForwardsPageTransitionsBuilder(),
              },
            ),
          ),
          home: const AppShell(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .92, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: const Text(
              'gym log',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  Workout get todayWorkout {
    switch (DateTime.now().weekday) {
      case DateTime.thursday:
        return workouts[1];
      case DateTime.saturday:
        return workouts[2];
      default:
        return workouts[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(today: todayWorkout),
      const ProgressPage(),
      const StatsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.015, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
        ),
      ),
      bottomNavigationBar: PremiumNav(
        selected: tab,
        onSelected: (value) => setState(() => tab = value),
      ),
    );
  }
}

class PremiumNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const PremiumNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const data = [
    (Icons.home_rounded, 'Сегодня'),
    (Icons.auto_graph_rounded, 'Прогресс'),
    (Icons.query_stats_rounded, 'Статистика'),
    (Icons.tune_rounded, 'Настройки'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0D12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          children: List.generate(data.length, (index) {
            final active = index == selected;
            final item = data[index];
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF241C40) : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 170),
                      scale: active ? 1 : .96,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$1,
                            size: 21,
                            color: active ? purpleSoft : textMuted,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                              color: active ? Colors.white : textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
