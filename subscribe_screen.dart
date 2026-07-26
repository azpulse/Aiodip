import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/app_state.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  Future<void> _buy(BuildContext context) async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!context.mounted) return;
      if (!state.isLoggedIn) return;
    }
    try {
      await state.subscribeViaStore();
      if (!context.mounted) return;
      if (!state.isEntitled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase not completed')),
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = state.error ?? e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!context.mounted) return;
      if (!state.isLoggedIn) return;
    }
    try {
      await state.restoreStorePurchases();
      if (!context.mounted) return;
      if (state.isEntitled) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No active subscription found on ${state.billing.storeLabel}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final quota = state.checkoutQuota;
    final price = quota
        ? AppConstants.money(AppConstants.priceQuotaCents)
        : AppConstants.money(AppConstants.priceFullCents);
    final store = state.billing.storeLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ AIODIP'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DJ Aiodip Pro',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              quota
                  ? (state.unlockedByInvites
                      ? 'Your invite discount is unlocked. Pay $price/month via $store.'
                      : 'Quota code applied. Pay $price/month via $store.')
                  : 'Billed through $store. First 7 days free, then \$16/month.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _feat('Edit every track', 'BPM, cut, cues, transitions'),
            _feat('2 or 4 channel mixer', 'Sync, samples, assign decks'),
            _feat('Record your mix', 'Capture while you play'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!quota)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'Good deal · first 7 days free',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    quota ? 'Your price' : 'Then',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quota ? price : '\$16',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Paid via $store · cancel in $store settings',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: state.busy ? null : () => _buy(context),
              child: Text(
                state.busy
                    ? 'Opening $store…'
                    : (quota
                        ? 'Subscribe — $price/month'
                        : 'Start free trial · Pay with $store'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: state.busy ? null : () => _restore(context),
              child: Text('Restore $store purchases'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feat(String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  sub,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
