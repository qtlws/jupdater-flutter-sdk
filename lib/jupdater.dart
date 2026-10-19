/// JUpdater - update checker with built-in force-update overlay for Flutter.
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await JUpdater.instance.init(JUpdaterConfig.managed(apiKey: 'YOUR_KEY'));
///   runApp(JUpdater.instance.wrap(const MyApp()));
/// }
/// ```
library jupdater;

export 'src/jupdater_base.dart' show JUpdater;
export 'src/models/jupdater_config.dart'
    show JUpdaterConfig, JUpdaterTexts, LaterBehavior, UpdateUiBuilder;
export 'src/models/update_actions.dart' show UpdateActions;
export 'src/models/update_result.dart' show UpdateResult;
export 'src/desktop/jupdater_desktop.dart' show JUpdaterDesktop;
