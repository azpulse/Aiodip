import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/app_state.dart';
import '../mixer/mixer_screen.dart';

/// Sprint 2 shell — track list + tools UI (DSP comes next).
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<AppState>().projects;
    final count = projects.isEmpty ? 0 : projects.first.trackCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit tracks'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MixerScreen()),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              count == 0
                  ? 'Your uploaded tracks will appear here for BPM, cut, cues, stems, and transitions.'
                  : '$count track(s) ready. Full waveform editor ships in the next sprint — continue to mixer.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tools', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('• BPM · Move · Cut · Delete'),
                    Text('• Transition kit (Echo Out, Spinback, …)'),
                    Text('• Stems (keep vocal / remove instruments)'),
                    Text('• Save cue → shows on mixer'),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MixerScreen()),
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
