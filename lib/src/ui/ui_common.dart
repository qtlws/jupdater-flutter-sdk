import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum JBreakpoint { compact, medium, expanded }

JBreakpoint breakpointOf(double width) {
  if (width < 600) return JBreakpoint.compact;
  if (width < 1024) return JBreakpoint.medium;
  return JBreakpoint.expanded;
}

/// iOS and macOS get Cupertino-style buttons, everything else Material.
bool useCupertinoStyle() =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Primary (filled) or secondary button in the platform's native style.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center, maxLines: 1);
    if (useCupertinoStyle()) {
      return SizedBox(
        height: 50,
        child: primary
            ? CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: onPressed,
                child: text,
              )
            : CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: onPressed,
                child: text,
              ),
      );
    }
    return primary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: text,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style:
                OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: text,
          );
  }
}

/// "Download" glyph drawn with a painter, so the SDK needs no icon font
/// (works even if the host app disabled `uses-material-design`).
class UpdateGlyph extends StatelessWidget {
  const UpdateGlyph({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlyphPainter(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = background);

    final stroke = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final top = c.dy - r * 0.38;
    final tip = c.dy + r * 0.12;
    final head = r * 0.26;
    canvas.drawLine(Offset(c.dx, top), Offset(c.dx, tip), stroke);
    canvas.drawLine(Offset(c.dx - head, tip - head), Offset(c.dx, tip), stroke);
    canvas.drawLine(Offset(c.dx + head, tip - head), Offset(c.dx, tip), stroke);

    final tray = c.dy + r * 0.42;
    canvas.drawLine(
        Offset(c.dx - r * 0.38, tray), Offset(c.dx + r * 0.38, tray), stroke);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.background != background || old.foreground != foreground;
}

class JAssetImages {
  JAssetImages._();

  static const String sheetHeader = 'assets/ic_hl_btm_sheet.png';
  static const String blockingHeader = 'assets/ic_fl_bs_sheet.png';

  static const String _package = 'jupdater';
  static final Map<String, bool> _known = <String, bool>{};
  static final Map<String, Future<bool>> _pending = <String, Future<bool>>{};

  static bool? knownToExist(String name) => _known[name];

  static Future<bool> exists(String name) {
    return _pending.putIfAbsent(name, () async {
      var found = false;
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        found = manifest.listAssets().contains('packages/$_package/$name');
      } catch (_) {
        found = false;
      }
      _known[name] = found;
      return found;
    });
  }

  static ImageProvider provider(String name) =>
      AssetImage(name, package: _package);
}

class HeaderImageGate extends StatelessWidget {
  const HeaderImageGate({
    super.key,
    required this.assetName,
    required this.overrid,
    required this.builder,
  });

  final String assetName;
  final ImageProvider? overrid;
  final Widget Function(BuildContext context, ImageProvider? image) builder;

  @override
  Widget build(BuildContext context) {
    final custom = overrid;
    if (custom != null) return builder(context, custom);

    final known = JAssetImages.knownToExist(assetName);
    if (known != null) {
      return builder(context, known ? JAssetImages.provider(assetName) : null);
    }
    return FutureBuilder<bool>(
      future: JAssetImages.exists(assetName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return builder(
          context,
          snapshot.data! ? JAssetImages.provider(assetName) : null,
        );
      },
    );
  }
}

class HeaderPicture extends StatelessWidget {
  const HeaderPicture({
    super.key,
    required this.image,
    required this.aspectRatio,
    required this.fallback,
    this.borderRadius = BorderRadius.zero,
  });

  final ImageProvider image;
  final double aspectRatio;
  final Widget fallback;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image(
          image: image,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Center(child: fallback),
        ),
      ),
    );
  }
}
