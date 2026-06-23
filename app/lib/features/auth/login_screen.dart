import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: kDebugMode ? 'hr_admin@hr.test' : '');
  final _password = TextEditingController(text: kDebugMode ? 'password' : '');
  bool _busy = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthService>().canUseBiometrics().then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          TextButton(
            onPressed: () => context.read<LocaleProvider>().toggle(),
            child: Text(t.language, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.badge, size: 72, color: Color(0xFF1B5E20)),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.email, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _run(() => auth.login(_email.text.trim(), _password.text)),
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t.login),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(() => auth.loginWithBiometrics()),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(t.loginWithBiometrics),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
