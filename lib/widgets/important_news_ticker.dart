import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class ImportantNewsTicker extends StatefulWidget {
  const ImportantNewsTicker({
    super.key,
    required this.items,
    this.height = 24,
    this.horizontalPadding = 16,
  });

  final List<String> items;
  final double height;
  final double horizontalPadding;

  List<String> get newsItems => items;

  @override
  State<ImportantNewsTicker> createState() => _ImportantNewsTickerState();
}

class _ImportantNewsTickerState extends State<ImportantNewsTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  void _setPaused(bool value) {
    if (_paused == value) return;
    setState(() => _paused = value);
    if (_paused) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _tickerTextStyle => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  @override
  Widget build(BuildContext context) {
    final items = widget.items
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    if (items.isEmpty) {
      return SizedBox(height: widget.height);
    }

    final text = items.join(' • ');
    final painter = TextPainter(
      text: TextSpan(text: text, style: _tickerTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final textWidth = painter.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - (widget.horizontalPadding * 2);
        if (available <= 0) {
          return SizedBox(height: widget.height);
        }

        const gap = 56.0;
        final trackWidth = textWidth + gap;

        return MouseRegion(
          onEnter: (_) => _setPaused(true),
          onExit: (_) => _setPaused(false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) => _setPaused(true),
            onTapUp: (_) => _setPaused(false),
            onTapCancel: () => _setPaused(false),
            child: Container(
              height: widget.height,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                border: const Border.symmetric(
                  horizontal: BorderSide(
                    color: Color(0xFFDCDCDC),
                    width: 0.5,
                  ),
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.horizontalPadding,
                ),
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final offset = -(_controller.value * trackWidth);

                      return OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: 0,
                        maxWidth: double.infinity,
                        child: Transform.translate(
                          offset: Offset(offset, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(text, style: _tickerTextStyle, maxLines: 1),
                              const SizedBox(width: gap),
                              Text(text, style: _tickerTextStyle, maxLines: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
