import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../jupdater_base.dart';
import 'default_blocking_screen.dart';
import 'default_update_sheet.dart';
import 'frames.dart';
import 'ui_scope.dart';
import 'ui_state.dart';

/// Sits above the whole app (above MaterialApp / Navigator). While a forced
/// update is active, the app below is made inert: no touches, no focus, no
/// semantics, and an opaque screen covers it.
class JUpdaterHost extends StatelessWidget {
  const JUpdaterHost({super.key, required this.child});

  final Widget child;

  static const Set<String> _rtlLanguages = <String>{
    'ar', 'he', 'fa', 'ur', 'ps', 'sd', 'ug', 'yi', 'dv', 'ckb', //
  };

  @override
  Widget build(BuildContext context) {
    final lang = PlatformDispatcher.instance.locale.languageCode;
    final direction = _rtlLanguages.contains(lang)
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: ValueListenableBuilder<UpdateUiState>(
        valueListenable: JUpdater.instance.uiState,
        child: child,
        builder: (context, state, appChild) {
          final blocking = state.kind == UpdateUiKind.blocking;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ExcludeFocus(
                excluding: blocking,
                child: ExcludeSemantics(
                  excluding: blocking,
                  child: AbsorbPointer(absorbing: blocking, child: appChild),
                ),
              ),
              if (state.kind != UpdateUiKind.none && state.result != null)
                Positioned.fill(child: _OverlayLayer(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _OverlayLayer extends StatelessWidget {
  const _OverlayLayer({required this.state});

  final UpdateUiState state;

  @override
  Widget build(BuildContext context) {
    final updater = JUpdater.instance;
    final cfg = updater.config;
    final result = state.result;
    if (cfg == null || result == null) return const SizedBox.shrink();

    final actions = updater.actionsFor(result);
    final blocking = state.kind == UpdateUiKind.blocking;

    return UiScope(
      builder: (context) {
        if (blocking) {
          final custom = cfg.blockingBuilder;
          return BlockingFrame(
            texts: cfg.texts,
            child: custom != null
                ? custom(context, result, actions)
                : DefaultBlockingScreen(
                    result: result,
                    actions: actions,
                    texts: cfg.texts,
                    images: cfg.images,
                  ),
          );
        }
        final custom = cfg.sheetBuilder;
        return SheetFrame(
          onScrimTap: actions.later,
          child: custom != null
              ? custom(context, result, actions)
              : DefaultUpdateSheet(
                  result: result,
                  actions: actions,
                  texts: cfg.texts,
                  images: cfg.images,
                ),
        );
      },
    );
  }
}
