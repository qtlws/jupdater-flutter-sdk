import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The overlay is rendered *above* the app's MaterialApp, so it has no Theme,
/// MediaQuery or Localizations of its own. This widget supplies them (with the
/// platform's light/dark setting) so default and custom UIs behave normally.
class UiScope extends StatelessWidget {
  const UiScope({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(
        builder: (context) {
          final brightness = MediaQuery.platformBrightnessOf(context);
          final theme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E88E5),
              brightness: brightness,
            ),
          );
          return Localizations(
            locale: const Locale('en', 'US'),
            delegates: const <LocalizationsDelegate<dynamic>>[
              DefaultWidgetsLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
            ],
            child: Theme(
              data: theme,
              child: Builder(builder: builder),
            ),
          );
        },
      ),
    );
  }
}
