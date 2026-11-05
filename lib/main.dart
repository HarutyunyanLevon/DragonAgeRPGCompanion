import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'shared/app_shell.dart';
import 'shared/theme.dart';
import 'shared/theme_provider.dart';
import 'shared/theme_specs.dart';

void main() {
  runApp(const ProviderScope(child: CompanionApp()));
}

class CompanionApp extends ConsumerWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The saved theme loads in a moment; until then the classic look shows.
    final themeId =
        ref.watch(themeIdProvider).valueOrNull ?? AppThemeId.classic;

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(themeId),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShell(),
    );
  }
}
