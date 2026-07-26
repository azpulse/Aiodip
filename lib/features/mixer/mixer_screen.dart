import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../done/done_screen.dart';

/// Sprint 2 shell — interactive layout matching product UX.
class MixerScreen extends StatefulWidget {
  const MixerScreen({super.key});

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  int channels = 2;
  double masterBpm = 124;
  bool syncOn = false;
  int cueDeck = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mixer'),
        actions: [
          TextButton(
            onPressed: () => setState(() => channels = channels == 2 ? 4 : 2),
            child: Text('$channels CH'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              const Text('Channels', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Text('pick 2 or 4',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 4, label: Text('4')),
                ],
                selected: {channels},
                onSelectionChanged: (s) => setState(() => channels = s.first),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('BPM', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    initialValue: masterBpm.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => masterBpm = double.tryParse(v) ?? masterBpm,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: syncOn ? AppColors.accent : AppColors.surface,
                    foregroundColor: syncOn ? AppColors.onAccent : Colors.white,
                  ),
                  onPressed: () => setState(() => syncOn = !syncOn),
                  child: const Text('Sync'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(channels.clamp(1, 4), (i) {
              final n = i + 1;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == channels - 1 ? 0 : 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text('Deck $n',
                          style: const TextStyle(
                              color: AppColors.accent, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Gain  Hi  Mid  Low  Filter',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Container(
                        height: 90,
                        width: 28,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 50,
                          width: 6,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            backgroundColor:
                                cueDeck == n ? AppColors.accent : AppColors.surfaceElevated,
                            foregroundColor:
                                cueDeck == n ? AppColors.onAccent : Colors.white,
                          ),
                          onPressed: () => setState(() => cueDeck = n),
                          child: const Text('Cue'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoneScreen()),
            ),
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }
}
