import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/news_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum NewsRotationSpeed { medium, fast }

class ImportantNewsRotator extends StatefulWidget {
  const ImportantNewsRotator({
    super.key,
    required this.items,
    this.speed = NewsRotationSpeed.medium,
  });

  final List<NewsItem> items;
  final NewsRotationSpeed speed;

  @override
  State<ImportantNewsRotator> createState() => _ImportantNewsRotatorState();
}

class _ImportantNewsRotatorState extends State<ImportantNewsRotator>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _index = 0;

  late final AnimationController _swingController;

  Duration get _rotationInterval {
    switch (widget.speed) {
      case NewsRotationSpeed.fast:
        return const Duration(milliseconds: 1800);
      case NewsRotationSpeed.medium:
        return const Duration(milliseconds: 2800);
    }
  }

  Duration get _swingDuration {
    switch (widget.speed) {
      case NewsRotationSpeed.fast:
        return const Duration(milliseconds: 700);
      case NewsRotationSpeed.medium:
        return const Duration(milliseconds: 1000);
    }
  }

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(vsync: this, duration: _swingDuration)
      ..repeat(reverse: true);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant ImportantNewsRotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _swingController.duration = _swingDuration;
      _swingController
        ..stop()
        ..repeat(reverse: true);
      _startTimer();
    } else if (oldWidget.items.length != widget.items.length) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;
    _timer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.items.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return Text('No news available', style: AppTextStyles.body);
    }

    final current = items[_index];

    return ClipRect(
      child: AnimatedBuilder(
        animation: _swingController,
        builder: (context, child) {
          final t = _swingController.value;
          final angle = (t - 0.5) * 0.06;
          final dx = (t - 0.5) * 10;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(angle: angle, child: child),
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            final offsetTween = Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: animation.drive(offsetTween), child: child),
            );
          },
          child: Container(
            key: ValueKey(current.title),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              current.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
          ),
        ),
      ),
    );
  }
}

