import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// A drop-in smooth architectural logo loader widget.
class LogoLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final Duration duration;

  const LogoLoadingIndicator({
    super.key,
    this.size = 180.0,
    this.color,
    this.strokeWidth = 5.0, // Scaled for a clean slender look
    this.duration = const Duration(milliseconds: 2800),
  });

  @override
  State<LogoLoadingIndicator> createState() => _LogoLoadingIndicatorState();
}

class _LogoLoadingIndicatorState extends State<LogoLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    // Smooth architectural cubic easing
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = widget.color ??
        (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E2F4D));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LogoPathPainter(
            progress: _animation.value,
            color: effectiveColor,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _LogoPathPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LogoPathPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  // Base canvas coordinate reference from design: 400 x 400
  static const double _viewBoxSize = 400.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Uniform scale to fit parent size
    final double scale = size.width / _viewBoxSize;
    canvas.save();
    canvas.scale(scale, scale);

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * (1 / scale)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Define all 6 authentic architectural segments
    final List<Path> segments = [
      // 1. Column 1 (Leftmost with ~32° angled pitch top)
      Path()
        ..moveTo(76, 318)
        ..lineTo(76, 172)
        ..lineTo(91, 162),

      // 2. Column 2
      Path()
        ..moveTo(116, 318)
        ..lineTo(116, 142)
        ..lineTo(131, 132),

      // 3. Column 3
      Path()
        ..moveTo(156, 318)
        ..lineTo(156, 112)
        ..lineTo(171, 102),

      // 4. Column 4 Foundation (Lower pillar)
      Path()
        ..moveTo(196, 318)
        ..lineTo(196, 240),

      // 5. Central Spire & Roof Apex (Upper split pillar + gable drop)
      Path()
        ..moveTo(196, 222)
        ..lineTo(196, 68)
        ..lineTo(252, 107)
        ..lineTo(252, 244),

      // 6. Outer Architectural Facade & Base Return Hook
      Path()
        ..moveTo(272, 122)
        ..lineTo(302, 147)
        ..lineTo(302, 280)
        ..lineTo(220, 280),
    ];

    // Compute progress cycle:
    // 0.0 -> 0.65: Sequential organic draw-in
    // 0.65 -> 0.80: Graceful hold at 100% completed form
    // 0.80 -> 1.00: Soft unwind exit
    double drawFactor;
    if (progress <= 0.65) {
      drawFactor = progress / 0.65;
    } else if (progress <= 0.80) {
      drawFactor = 1.0;
    } else {
      drawFactor = 1.0 - ((progress - 0.80) / 0.20);
    }

    final int totalSegments = segments.length;
    for (int i = 0; i < totalSegments; i++) {
      // Stagger start points across segments (0.0 to 0.70 of drawing phase)
      final double segStart = (i / totalSegments) * 0.70;
      final double segEnd = math.min(1.0, segStart + 0.30);

      double segProgress;
      if (drawFactor <= segStart) {
        segProgress = 0.0;
      } else if (drawFactor >= segEnd) {
        segProgress = 1.0;
      } else {
        segProgress = (drawFactor - segStart) / (segEnd - segStart);
        // Soft per-segment sine ease
        segProgress = (1.0 - math.cos(segProgress * math.pi)) / 2.0;
      }

      if (segProgress > 0) {
        _drawTrimmedPath(canvas, segments[i], segProgress, paint);
      }
    }

    canvas.restore();
  }

  /// Trims and renders the path smoothly based on the animation progress
  void _drawTrimmedPath(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
  ) {
    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final PathMetric metric in path.computeMetrics()) {
      final double extractLength = metric.length * progress;
      final Path extracted = metric.extractPath(0.0, extractLength);
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
