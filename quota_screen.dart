import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/app_state.dart';
import '../gate/login_screen.dart';
import '../gate/subscribe_screen.dart';

class QuotaScreen extends StatefulWidget {
  const QuotaScreen({super.key});

  @override
  State<QuotaScreen> createState() => _QuotaScreenState();
}

class _QuotaScreenState extends State<QuotaScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.refreshQuota();
      final name = (state.profile?.displayName ?? 'USER')
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), '');
      final base = name.length > 8 ? name.substring(0, 8) : name;
      if (state.myQuota == null) _codeCtrl.text = 'AIODIP-$base';
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final state = context.read<AppState>();
    if (!state.isLoggedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || !state.isLoggedIn) return;
    }
    try {
      await state.createQuotaCode(_codeCtrl.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Could not create code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = state.myQuota;

    return Scaffold(
      appBar: AppBar(
        title: Text(q == null ? 'Create code' : 'Quota code'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        ],
      ),
      body: q == null ? _createView(state) : _manageView(state),
    );
  }

  Widget _createView(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create a quota code', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Make your code, share it with friends. They pay \$3.20/month. When 4 or more subscribe with it, Subscribe at \$3.20 unlocks for you.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Your code',
              hintText: 'AIODIP-YOURNAME',
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: state.busy ? null : _create,
            child: Text(state.busy ? 'Creating…' : 'Create code'),
          ),
        ],
      ),
    );
  }

  Widget _manageView(AppState state) {
    final q = state.myQuota!;
    final pct = (q.useCount / q.unlockAt).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your quota code', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Share your code. Open this page anytime to check how many friends used it and if your \$3.20 price is ready.',
          ),
          const SizedBox(height: 14),
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
                const Text('Code', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  q.code,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.black,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${q.useCount} / ${q.unlockAt} used your code',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(
                      q.unlocked
                          ? '80% off unlocked'
                          : '${q.unlockAt - q.useCount} more to unlock',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: q.unlocked ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: q.code));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied ${q.code}')),
              );
            },
            child: const Text('Copy code'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                text:
                    'Join DJ Aiodip with my quota code ${q.code} — Pro for \$3.20/month (80% off).',
              ));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share text copied')),
              );
            },
            child: const Text('Share code'),
          ),
          const Spacer(),
          if (q.unlocked) ...[
            ElevatedButton(
              onPressed: () {
                state.prepareInviterQuotaCheckout();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                );
              },
              child: Text('Subscribe — ${AppConstants.money(AppConstants.priceQuotaCents)}/month'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                state.prepareFullCheckout();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                );
              },
              child: const Text('Subscribe — \$16/month'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                state.prepareFullCheckout();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                );
              },
              child: const Text('Subscribe — \$16/month'),
            ),
            const SizedBox(height: 8),
            const Text(
              'When 4 friends use your code, Subscribe — \$3.20/month appears here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
