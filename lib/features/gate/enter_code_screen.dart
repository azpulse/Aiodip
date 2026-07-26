import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import 'subscribe_screen.dart';

class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final state = context.read<AppState>();
    try {
      await state.applyQuotaCode(_ctrl.text);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscribeScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Invalid code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AppState>().busy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ AIODIP'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter quota code', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Got a code from a friend? Enter it to unlock Pro for \$3.20/month (80% off).',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Quota code',
                hintText: 'e.g. AIODIP-AZIZ',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: busy ? null : _continue,
              child: Text(busy ? 'Checking…' : 'Continue with \$3.20'),
            ),
          ],
        ),
      ),
    );
  }
}
