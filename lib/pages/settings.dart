import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../store.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _restOptions = [60, 90, 120, 150, 180];

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: panel,
        title: const Text(
          'Очистить данные?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Будут удалены веса, повторы, заметки и история тренировок '
          'на этом устройстве. Отменить это будет нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await store.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Локальные данные удалены')),
        );
      }
    }
  }

  Future<void> _export(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Резервная копия скопирована в буфер обмена'),
          ),
        );
    }
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text(
          'Импорт данных',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 6,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              hintText: 'Вставь сюда JSON-копию из другого устройства',
              filled: true,
              fillColor: panel2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: purple),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = store.importJson(controller.text.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Данные импортированы'
                  : 'Копия повреждена или не похожа на данные приложения',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 35),
      children: [
        const Text(
          'НАСТРОЙКИ',
          style: TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Приложение',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.6,
          ),
        ),
        const SizedBox(height: 20),
        _SettingsSection(
          title: 'ОТДЫХ',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Длительность таймера',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Таймер стартует после отметки выполненного подхода.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 10,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final seconds in _restOptions)
                        _RestChip(
                          seconds: seconds,
                          selected: store.restSeconds == seconds,
                          onTap: () => store.setRestSeconds(seconds),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Свой вариант',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${store.restSeconds} сек',
                        style: const TextStyle(
                          color: purpleSoft,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: store.restSeconds.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 9,
                    onChanged: (v) => store.setRestSeconds(v.round()),
                  ),
                ],
              ),
            ),
            _SwitchRow(
              icon: Icons.play_circle_outline_rounded,
              title: 'Запускать автоматически',
              subtitle: 'Отсчёт стартует сразу после отметки подхода.',
              value: store.autoRest,
              onChanged: store.setAutoRest,
            ),
            _SwitchRow(
              icon: Icons.vibration_rounded,
              title: 'Вибро-отклик в конце',
              subtitle: 'Лёгкая вибрация, когда отдых закончился.',
              value: store.haptics,
              onChanged: store.setHaptics,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          title: 'ТРЕНИРОВКИ',
          children: [
            _SettingsRow(
              icon: Icons.repeat_rounded,
              title: 'Подходы по умолчанию',
              subtitle:
                  'Каждое новое упражнение начинается ровно с двух подходов.',
              trailing: const Text(
                '2',
                style: TextStyle(
                  color: purpleSoft,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _SettingsRow(
              icon: Icons.schedule_rounded,
              title: 'Расписание',
              subtitle: 'A — вторник, B — четверг, C — суббота.',
              trailing: const Icon(
                Icons.calendar_month_rounded,
                color: purpleSoft,
                size: 19,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          title: 'ДАННЫЕ',
          children: [
            _SettingsRow(
              icon: Icons.phone_android_rounded,
              title: 'Локальное хранилище',
              subtitle:
                  'Сохраняется автоматически на устройстве: ${store.totalSessions} тренировок, '
                  '${store.totalCompletedSets} подходов.',
              trailing: const Icon(
                Icons.check_circle_rounded,
                color: green,
                size: 21,
              ),
            ),
            _SettingsRow(
              icon: Icons.copy_all_rounded,
              title: 'Резервная копия',
              subtitle: 'Скопировать все данные в буфер обмена.',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: textMuted,
              ),
              onTap: () => _export(context),
            ),
            _SettingsRow(
              icon: Icons.paste_rounded,
              title: 'Импорт копии',
              subtitle: 'Вставить данные с другого устройства.',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: textMuted,
              ),
              onTap: () => _import(context),
            ),
            _SettingsRow(
              icon: Icons.delete_outline_rounded,
              title: 'Очистить всё',
              subtitle: 'Удалить историю, веса и заметки.',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: textMuted,
              ),
              onTap: () => _clear(context),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Center(
          child: Text(
            'gym log • данные хранятся только на устройстве',
            style: TextStyle(
              color: textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RestChip extends StatelessWidget {
  final int seconds;
  final bool selected;
  final VoidCallback onTap;

  const _RestChip({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF241C40) : panel2,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? purple : border,
            ),
          ),
          child: Text(
            '$seconds с',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: selected ? purpleSoft : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF211B38),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: purpleSoft, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: border),
          ),
          child: Column(
            children: List.generate(
              children.length,
              (index) => Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    const Divider(height: 1, color: border, indent: 58),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B38),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: purpleSoft, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
