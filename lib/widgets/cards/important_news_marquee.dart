import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/news_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ImportantNewsMarquee extends StatefulWidget {
  const ImportantNewsMarquee({
    super.key,
    required this.items,
    this.pixelsPerSecond = 48,
    this.height = 54,
  });

  final List<NewsItem> items;
  final double pixelsPerSecond;
  final double height;

  @override
  State<ImportantNewsMarquee> createState() => _ImportantNewsMarqueeState();
}

class _ImportantNewsMarqueeState extends State<ImportantNewsMarquee> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  DateTime? _lastTick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(covariant ImportantNewsMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.pixelsPerSecond != widget.pixelsPerSecond) {
      _restart();
    }
  }

  void _restart() {
    _stop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (!_controller.hasClients) return;
    if (widget.items.length <= 1) return;
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;

      final now = DateTime.now();
      final dtMs = now.difference(_lastTick!).inMilliseconds;
      _lastTick = now;

      final delta = widget.pixelsPerSecond * (dtMs / 1000);
      final next = _controller.offset + delta;

      final max = _controller.position.maxScrollExtent;
      if (max <= 0) return;

      if (next >= max) {
        _controller.jumpTo(0);
      } else {
        _controller.jumpTo(next);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _lastTick = null;
  }

  @override
  void dispose() {
    _stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No news available',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemBuilder: (context, index) {
                final item = widget.items[index % widget.items.length];
                return Center(
                  child: Text(
                    item.title,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return Container(
                  width: 14,
                  alignment: Alignment.center,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
              itemCount: widget.items.length * 20,
            ),
          ),
        ),
      ),
    );
  }
}

