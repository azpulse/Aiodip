import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/media_asset.dart';
import '../copyright/copyright_badge.dart';

/// Phase 1 gate — cart handoff lands here. No editor until you confirm Phase 2.
class Phase2PlaceholderScreen extends StatelessWidget {
  const Phase2PlaceholderScreen({super.key, required this.cartItems});

  final List<MediaAsset> cartItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DJ Aiodip')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Phase 2 — Pre-Mix A/V Editing Suite',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.accent,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Phase 1 complete. Your cart (${cartItems.length} items) is ready '
              'to load into the editing workspace. Confirm with the team before '
              'we build Phase 2.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final asset = cartItems[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            asset.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        CopyrightBadge(
                          status: asset.copyrightStatus,
                          compact: true,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to start'),
            ),
          ],
        ),
      ),
    );
  }
}
