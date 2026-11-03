import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'character/providers.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: CompanionApp()));
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFC9A227), // gold accent
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const StartupPage(),
    );
  }
}

/// Temporary first screen: proves the rules load. Replaced by the real tabs later.
class StartupPage extends ConsumerWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(rulesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: rules.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text(l10n.rulesFailed(error.toString())),
          data: (data) => Text(l10n.rulesLoaded(
            data.classes.classes.length,
            data.backgrounds.backgrounds.length,
            data.talents.talents.length,
            data.spells.length,
          )),
        ),
      ),
    );
  }
}
