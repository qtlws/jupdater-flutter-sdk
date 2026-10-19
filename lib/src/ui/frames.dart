import 'package:flutter/material.dart';

import '../jupdater_base.dart';
import '../models/jupdater_config.dart';
import 'ui_common.dart';

/// Opaque full-screen frame for the forced-update UI. Also shows the
/// "press back again to exit" hint.
class BlockingFrame extends StatelessWidget {
  const BlockingFrame({super.key, required this.texts, required this.child});

  final JUpdaterTexts texts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: JUpdater.instance.backHintVisible,
                    builder: (context, visible, _) {
                      return AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.inverseSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                texts.backAgainHint,
                                style: TextStyle(
                                  color: scheme.onInverseSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrim + slide-in container for the optional-update sheet.
class SheetFrame extends StatefulWidget {
  const SheetFrame({super.key, required this.onScrimTap, required this.child});

  final VoidCallback onScrimTap;
  final Widget child;

  @override
  State<SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<SheetFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final compact = breakpointOf(size.width) == JBreakpoint.compact;

    final radius = compact
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : BorderRadius.circular(28);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FadeTransition(
          opacity: _controller,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onScrimTap,
            child: const ColoredBox(color: Color(0x8A000000)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: EdgeInsets.only(bottom: compact ? 0 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? double.infinity : 880,
                  maxHeight: size.height * 0.85,
                ),
                child: Material(
                  color: scheme.surface,
                  surfaceTintColor: scheme.surfaceTint,
                  elevation: 3,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
