import 'package:flutter/material.dart';

import '../models/jupdater_config.dart';
import '../models/update_actions.dart';
import '../models/update_result.dart';
import 'ui_common.dart';

class DefaultUpdateSheet extends StatelessWidget {
  const DefaultUpdateSheet({
    super.key,
    required this.result,
    required this.actions,
    required this.texts,
    this.images = const JUpdaterImages(),
  });

  static const double _imageRatio = 1080 / 600;

  final UpdateResult result;
  final UpdateActions actions;
  final JUpdaterTexts texts;
  final JUpdaterImages images;

  @override
  Widget build(BuildContext context) {
    final compact =
        breakpointOf(MediaQuery.sizeOf(context).width) == JBreakpoint.compact;

    return HeaderImageGate(
      assetName: JAssetImages.sheetHeader,
      overrid: images.sheetHeader,
      builder: (context, image) =>
      compact ? _compact(context, image) : _wide(context, image),
    );
  }

  Widget _compact(BuildContext context, ImageProvider? image) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = image != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (image != null)
          HeaderPicture(
            image: image,
            aspectRatio: _imageRatio,
            fallback: const UpdateGlyph(size: 72),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        Flexible(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, hasImage ? 20 : 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (!hasImage) ...<Widget>[
                      const UpdateGlyph(size: 48),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        result.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      result.message,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buttons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _wide(BuildContext context, ImageProvider? image) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final left = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (image != null)
          HeaderPicture(
            image: image,
            aspectRatio: _imageRatio,
            borderRadius: BorderRadius.circular(16),
            fallback: const UpdateGlyph(size: 96),
          )
        else
          const Center(child: UpdateGlyph(size: 96)),
        const SizedBox(height: 24),
        _buttons(),
      ],
    );

    final right = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          result.title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              result.message,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: left),
          const SizedBox(width: 32),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: AdaptiveButton(
            label: texts.laterButton,
            onPressed: actions.later,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AdaptiveButton(
            label: texts.updateButton,
            primary: true,
            onPressed: actions.hasUpdateUrl
                ? () {
              actions.update();
            }
                : null,
          ),
        ),
      ],
    );
  }
}