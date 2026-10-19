import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tracks.dart';
import 'motion.dart';

/// The academy's signature control: seven track segments arranged like an
/// instrument dial, with a brass needle that swings to the chosen track.
class TrackDial extends StatefulWidget {
  const TrackDial({
    super.key,
    required this.counts,
    required this.total,
    required this.lang,
    required this.allLabel,
    required this.onSelect,
  });

  final Map<String, int> counts;
  final int total;
  final String lang;
  final String allLabel;
  final ValueChanged<String> onSelect;

  @override
  State<TrackDial> createState() => _TrackDialState();
}

class _TrackDialState extends State<TrackDial> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 120));
  int? _selected;
  double _needle = -math.pi / 2;
  bool _started = false;

  double get _dir => widget.lang == 'ar' ? -1 : 1;
  double get _step => 2 * math.pi / tracks.length;
  double _midAngle(int i) => -math.pi / 2 + _dir * (i + 0.5) * _step;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _intro.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _intro.forward();
      });
      _spin.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TrackDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang && _selected != null) {
      _pointTo(_selected!);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _pointTo(int index) {
    final target = _midAngle(index);
    // Shortest way round.
    var delta = (target - _needle) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    _needle += delta;
  }

  void _handleTap(Offset local, Size size) {
    final c = size.center(Offset.zero);
    final d = local - c;
    final s = size.shortestSide;
    final dist = d.distance;
    if (dist < s * 0.24 || dist > s * 0.5) return;
    var t = ((math.atan2(d.dy, d.dx) + math.pi / 2) * _dir) % (2 * math.pi);
    if (t < 0) t += 2 * math.pi;
    final index = math.min(tracks.length - 1, math.max(0, (t / _step).floor()));
    setState(() {
      _selected = index;
      _pointTo(index);
    });
    widget.onSelect(tracks[index].id);
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selected == null ? null : tracks[_selected!].id;
    final count = selectedId == null ? widget.total : (widget.counts[selectedId] ?? 0);
    final label = selectedId == null ? widget.allLabel : trackOf(selectedId).name(widget.lang);
    final textDir = widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    final reduce = reduceMotion(context);
    final labels = [for (final t in tracks) t.shortName(widget.lang)];

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        // Built once per layout, not on every animation frame.
        final center = SizedBox(
          width: size.width * 0.42,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CountUp(
              value: count,
              duration: const Duration(milliseconds: 600),
              style: displayStyle(context, size.width * 0.12, color: Palette.light.onNavy, weight: FontWeight.w700, height: 1),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                label,
                key: ValueKey(label),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(color: Palette.light.onNavyMuted, fontSize: 12.5, height: 1.35),
              ),
            ),
          ]),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details.localPosition, size),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _needle),
            duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            child: center,
            builder: (context, needle, centerChild) => AnimatedBuilder(
              animation: Listenable.merge([_intro, _spin]),
              child: centerChild,
              builder: (context, child) => Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DialPainter(
                      progress: _intro.value,
                      spin: _spin.value * 2 * math.pi,
                      needle: needle,
                      selected: _selected,
                      labels: labels,
                      dir: _dir,
                      textDirection: textDir,
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: Curves.easeOut.transform((_intro.value * 1.6 - 0.4).clamp(0.0, 1.0).toDouble()),
                    child: child,
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.spin,
    required this.needle,
    required this.selected,
    required this.labels,
    required this.dir,
    required this.textDirection,
  });

  final double progress;
  final double spin;
  final double needle;
  final int? selected;
  final List<String> labels;
  final double dir;
  final TextDirection textDirection;

  static const _onNavy = Color(0xFFEEF2F8);
  static const _navy = Color(0xFF0D2140);
  static const _brass = Palette.brassOnNavy;
  static const _ink = Color(0xFF1A1205);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r1 = s * 0.455;
    final r0 = s * 0.265;
    final n = labels.length;
    final step = 2 * math.pi / n;
    const gap = 0.014;

    // Slowly turning tick ring.
    final tickPaint = Paint()
      ..color = fade(_onNavy, 0.32 * progress)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = fade(_onNavy, 0.7 * progress)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 70; i++) {
      final a = spin + i / 70 * 2 * math.pi;
      final major = i % 10 == 0;
      final ra = s * 0.472;
      final rb = major ? s * 0.497 : s * 0.485;
      canvas.drawLine(
        c + Offset(math.cos(a) * ra, math.sin(a) * ra),
        c + Offset(math.cos(a) * rb, math.sin(a) * rb),
        major ? majorPaint : tickPaint,
      );
    }

    // Segments appear one after another.
    for (var i = 0; i < n; i++) {
      final local = (progress * (n + 3) - i).clamp(0.0, 1.0).toDouble();
      final appear = Curves.easeOutCubic.transform(local);
      if (appear <= 0) continue;
      final mid = -math.pi / 2 + dir * (i + 0.5) * step;
      final a0 = mid - step / 2 + gap;
      final sweep = step - 2 * gap;
      final outer = r0 + (r1 - r0) * (0.6 + 0.4 * appear);
      final active = selected == i;

      final path = Path()
        ..arcTo(Rect.fromCircle(center: c, radius: outer), a0, sweep, true)
        ..arcTo(Rect.fromCircle(center: c, radius: r0), a0 + sweep, -sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = active ? _brass : fade(_onNavy, 0.08 * appear));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _navy,
      );

      final rm = (r0 + r1) / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: fade(active ? _ink : _onNavy, appear),
            fontSize: s * 0.034,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: textDirection,
        maxLines: 2,
      )..layout(maxWidth: s * 0.17);
      final pos = c + Offset(math.cos(mid) * rm, math.sin(mid) * rm) - Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    }

    // Dashed inner ring and the needle.
    final needleT = ((progress - 0.55) / 0.45).clamp(0.0, 1.0).toDouble();
    if (needleT <= 0) return;
    final ring = Paint()
      ..color = fade(_onNavy, 0.14 * needleT)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rr = r0 - s * 0.03;
    for (var i = 0; i < 48; i++) {
      final a = i / 48 * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: rr), a, 0.04, false, ring);
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(needle);
    final tip = rr + s * 0.005;
    final head = Path()
      ..moveTo(tip - s * 0.05, -s * 0.017)
      ..lineTo(tip, 0)
      ..lineTo(tip - s * 0.05, s * 0.017)
      ..close();
    final alpha = needleT * (selected == null ? 0.6 : 1.0);
    canvas.drawPath(
      head,
      Paint()
        ..color = fade(_brass, 0.45 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(head, Paint()..color = fade(_brass, alpha));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => true;
}
