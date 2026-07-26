import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/media_asset.dart';
import '../copyright/copyright_badge.dart';
import '../phase2/phase2_placeholder_screen.dart';
import 'cart_controller.dart';

class CartReviewScreen extends StatelessWidget {
  const CartReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: cart.clear,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Text(
                'Cart is empty. Browse a platform and add assets.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final asset = cart.items[index];
                return _CartRow(
                  asset: asset,
                  onRemove: () => cart.remove(asset),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${cart.count} item${cart.count == 1 ? '' : 's'} ready for the editing suite',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        final snapshot = List<MediaAsset>.from(cart.items);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => Phase2PlaceholderScreen(
                              cartItems: snapshot,
                            ),
                          ),
                        );
                      },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.asset, required this.onRemove});

  final MediaAsset asset;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${asset.platform.label} · ${asset.artist}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                CopyrightBadge(status: asset.copyrightStatus, compact: true),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
