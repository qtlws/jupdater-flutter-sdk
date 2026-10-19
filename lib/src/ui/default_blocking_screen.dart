import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/jupdater_config.dart';
import '../models/update_actions.dart';
import '../models/update_result.dart';
import 'ui_common.dart';

class DefaultBlockingScreen extends StatelessWidget {
  const DefaultBlockingScreen({
    super.key,
    required this.result,
    required this.actions,
    required this.texts,
    this.images = const JUpdaterImages(),
  });

  static const Color _lightBackground = Color(0xFFDDEBF6);
  static const String _brandName = 'JUpdater';
  static const String _poweredBy = 'Powered by QTLWS';

  final UpdateResult result;
  final UpdateActions actions;
  final JUpdaterTexts texts;
  final JUpdaterImages images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact =
        breakpointOf(MediaQuery.sizeOf(context).width) == JBreakpoint.compact;
    final background =
    theme.brightness == Brightness.light ? _lightBackground : scheme.surface;

    return HeaderImageGate(
      assetName: JAssetImages.blockingHeader,
      overrid: images.blockingHeader,
      builder: (context, image) {
        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: compact ? _compact(context, image) : _wide(context, image),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ compact

  Widget _compact(BuildContext context, ImageProvider? image) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final Widget art = image != null
        ? LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, screenHeight * 0.45);
        return Center(
          child: SizedBox(
            width: side,
            child: HeaderPicture(
              image: image,
              aspectRatio: 1,
              fallback: const UpdateGlyph(size: 96),
            ),
          ),
        );
      },
    )
        : const Padding(
      padding: EdgeInsets.only(top: 32),
      child: Center(child: UpdateGlyph(size: 96)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                art,
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _brand(theme, scheme),
                      const SizedBox(height: 28),
                      Text(
                        result.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.message,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: _buttons(),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------- wide

  Widget _wide(BuildContext context, ImageProvider? image) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Widget art = image != null
        ? Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: HeaderPicture(
          image: image,
          aspectRatio: 1,
          borderRadius: BorderRadius.circular(20),
          fallback: const UpdateGlyph(size: 96),
        ),
      ),
    )
        : const Center(child: UpdateGlyph(size: 112));

    final left = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        art,
        const SizedBox(height: 20),
        _brand(theme, scheme),
        const SizedBox(height: 28),
        _buttons(),
      ],
    );

    final right = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          result.title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          result.message,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 48),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Material(
                  color: scheme.surfaceContainerLow,
                  elevation: 1,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: left),
                        const SizedBox(width: 40),
                        Expanded(child: right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ pieces

  Widget _brand(ThemeData theme, ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          _brandName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _poweredBy,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buttons() {
    final update = AdaptiveButton(
      label: texts.updateButton,
      primary: true,
      onPressed: actions.hasUpdateUrl
          ? () {
        actions.update();
      }
          : null,
    );
    if (!actions.canCloseApp) return update;
    final close = AdaptiveButton(
      label: texts.closeAppButton,
      onPressed: actions.closeApp,
    );
    return Row(
      children: <Widget>[
        Expanded(child: close),
        const SizedBox(width: 12),
        Expanded(child: update),
      ],
    );
  }
}