import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/app_state.dart';
import '../editor/editor_screen.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'],
      allowMultiple: true,
    );
    if (result == null || !context.mounted) return;
    final state = context.read<AppState>();
    for (final f in result.files) {
      await state.addDraftTrack(f.name, path: f.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Project'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Upload files', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Each audio file becomes its own track.'),
            const SizedBox(height: 14),
            Expanded(
              child: state.draftTracks.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'No audio yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.draftTracks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = state.draftTracks[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.accent,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: AppColors.onAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(t.durationLabel ?? 'Track',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _pick(context),
              child: const Text('+ Add audio'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: state.draftTracks.isEmpty
                  ? null
                  : () async {
                      try {
                        await state.saveDraftProject(title: 'Saturday Night Set');
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditorScreen()),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.error ?? 'Could not save')),
                        );
                      }
                    },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
