import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'enter_code_screen.dart';
import 'login_screen.dart';
import 'subscribe_screen.dart';
import '../quota/quota_screen.dart';
import '../../services/app_state.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'DJ',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  color: Colors.white,
                ),
              ),
              const Text(
                'AIODIP',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mix, edit, and record your sets in one place.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              ),
              const SizedBox(height: 8),
              const Text(
                'then \$16 / month',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().prepareFullCheckout();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                  );
                },
                child: const Text('Start free trial'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Log in'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EnterCodeScreen()),
                ),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'I have a code — '),
                      TextSpan(
                        text: '\$3.20',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuotaScreen()),
                ),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Create a quota code · get ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: '80% off',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
