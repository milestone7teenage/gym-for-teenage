import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<SessionRecord>> _sessionsFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
  }

  Future<List<SessionRecord>> _loadSessions() {
    return _loadSessionsAsync();
  }

  Future<List<SessionRecord>> _loadSessionsAsync() async {
    final store = GymStore();
    await store.init();
    return store.sessions;
  }

  Future<void> _pickImageById(String exerciseId) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('archive_photo_$exerciseId', base64);

      if (mounted) setState(() {});
    }
  }

  void _deletePhotoById(String exerciseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('archive_photo_$exerciseId');
    if (mounted) setState(() {});
  }

  Widget _buildPhotoPreview(String exerciseName, String base64) {
    final bytes = base64.isNotEmpty ? base64Decode(base64) : null;

    if (bytes == null) {
      return InkWell(
        onTap: () => _pickImageById(exerciseName),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: panel2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_rounded,
                color: textMuted,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Добавить фото',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          top: 0,
          child: _PhotoDeleteButton(
            onDelete: () => _deletePhotoById(exerciseName),
            child: Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        InkWell(
          onTap: () => _pickImageById(exerciseName),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: panel2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: purpleSoft),
            ),
            child: Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExercisePhotoCard(String exerciseName, String muscle, String exerciseId) {
    return FutureBuilder(
      future: _getPhotoBase64byId(exerciseId),
      builder: (context, snapshot) {
        final base64 = snapshot.data ?? '';
        return _buildPhotoPreview(exerciseId, base64);
      },
    );
  }

  Future<String> _getPhotoBase64byId(String exerciseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('archive_photo_$exerciseId') ?? '';
  }

  Widget _buildSessionCard(SessionRecord session) {
    final workout = workoutById(session.workoutId);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF211B38),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  workout?.id ?? session.workoutId,
                  style: const TextStyle(
                    color: purpleSoft,
                    fontSize: 14,
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
                      workout?.name ?? session.workoutId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_date(session.date)} • ${session.completedSets} подходов • ${session.volume.round()} кг',
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...session.exercises.map(
            (se) => _buildExercisePhotoCard(
              se.name,
              se.muscle,
              se.exerciseId,
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day}.${d.month}.${d.year}';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Архив прогресса',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пусто',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Здесь пока нет сохранённых тренировок.\n'
                    'Отметь подходы и нажми "Сохранить тренировку" — '
                    'записи появятся здесь.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          final sessions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return _buildSessionCard(sessions[index]);
            },
          );
        },
      ),
    );
  }
}

class _PhotoDeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  final Widget child;

  const _PhotoDeleteButton({
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -4,
      top: -4,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onDelete,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.close_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}