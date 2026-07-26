import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../home/home_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  final _name = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    try {
      if (_signUp) {
        await state.signUp(_email.text, _password.text, name: _name.text);
      } else {
        await state.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      if (state.isEntitled) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in. Start a trial or use a code to continue.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Auth failed')),
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
            Text(_signUp ? 'Create account' : 'Log in',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (_signUp) ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: busy ? null : _submit,
              child: Text(busy ? 'Please wait…' : (_signUp ? 'Sign up' : 'Log in')),
            ),
            TextButton(
              onPressed: () => setState(() => _signUp = !_signUp),
              child: Text(_signUp ? 'Have an account? Log in' : 'Need an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
