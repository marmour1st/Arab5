import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// True when the user asked the system to reduce motion.
bool reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

/// Fades and slides its child in, after an optional delay.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 22,
    this.duration = const Duration(milliseconds: 650),
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _a.value)), child: child),
      ),
    );
  }
}

/// A number that counts up to [value] (and animates again when it changes).
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1400),
  });

  final int value;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reduceMotion(context) ? Duration.zero : duration,
      curve: Curves.easeOutQuart,
      builder: (context, v, _) => Text(
        '$prefix${fmtNum(v.round())}',
        style: style,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// Shrinks slightly while pressed, for a tactile feel. Taps go to the child.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.97});
  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Page transition: fade + gentle rise + slight scale.
Route<T> fadeThrough<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 460),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotion(context)) return child;
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
          child: ScaleTransition(scale: Tween<double>(begin: 0.98, end: 1).animate(curved), child: child),
        ),
      );
    },
  );
}

/// Circle that pops in, then a check mark that draws itself.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({super.key, this.size = 76});
  final double size;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _CheckPainter(t: _c.value, color: p.ok, background: p.okSoft),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.color, required this.background});
  final double t;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final circleT = Curves.easeOutBack.transform((t / 0.5).clamp(0.0, 1.0).toDouble());
    canvas.drawCircle(c, r * circleT, Paint()..color = background);

    final checkT = ((t - 0.35) / 0.65).clamp(0.0, 1.0).toDouble();
    if (checkT <= 0) return;
    final path = Path()
      ..moveTo(c.dx - r * 0.38, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.1, c.dy + r * 0.3)
      ..lineTo(c.dx + r * 0.42, c.dy - r * 0.28);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final eased = Curves.easeOutCubic.transform(checkT);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * eased), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.t != t || old.color != color;
}

/// Gray placeholder block that gently pulses while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 120, this.radius = 18});
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context) && !_c.isAnimating) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(p.surface, p.surface2, 0.35 + 0.65 * math.sin(_c.value * math.pi / 2)),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: p.line),
        ),
      ),
    );
  }
}
