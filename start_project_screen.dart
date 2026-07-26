import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../platforms/platform_select_screen.dart';

class StartProjectScreen extends StatelessWidget {
  const StartProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                'DJ Aiodip',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      color: AppColors.accent,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Professional A/V DJ Workstation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PlatformSelectScreen(),
                    ),
                  );
                },
                child: const Text('Start a project'),
              ),
              const SizedBox(height: 16),
              Text(
                'Phase 1 — Import & Copyright Analysis',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
