import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth_service.dart';
import 'core/locale_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const HrApp());
}

class HrApp extends StatelessWidget {
  const HrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(create: (_) => AuthService()..bootstrap()),
      ],
      child: Consumer2<LocaleProvider, AuthService>(
        builder: (context, localeProvider, auth, _) {
          // Keep the API's Accept-Language in sync with the chosen locale.
          auth.localeCode = localeProvider.locale.languageCode;

          return MaterialApp(
            title: 'HR System',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF1B5E20),
              useMaterial3: true,
            ),
            home: _Root(auth: auth),
          );
        },
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}
