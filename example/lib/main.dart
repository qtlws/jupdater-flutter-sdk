import 'package:flutter/material.dart';
import 'package:jupdater/jupdater.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Initialise once, first thing in main().
  await JUpdater.instance.init(
    JUpdaterConfig.managed(
      apiKey: 'YOUR_API_KEY',
      laterBehavior: LaterBehavior.snooze, // or LaterBehavior.dismiss
      snoozeDuration: const Duration(hours: 12),
      debug: true,
      // Optional: use your own screens instead of the built-in ones.
      // blockingBuilder: (context, result, actions) => MyBlockingScreen(result, actions),
      // sheetBuilder: (context, result, actions) => MySheetContent(result, actions),
    ),
  );

  // 2) Optional: react to every finished check.
  JUpdater.instance.onUpdateCheckComplete = (result) {
    debugPrint('Update check: $result');
  };

  // 3) Wrap the app so the overlay can cover everything.
  runApp(JUpdater.instance.wrap(const ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JUpdater example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('JUpdater example')),
        body: Center(
          child: FilledButton(
            onPressed: () => JUpdater.instance.checkNow(),
            child: const Text('Check for updates now'),
          ),
        ),
      ),
    );
  }
}
