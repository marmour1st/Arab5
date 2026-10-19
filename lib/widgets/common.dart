import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../core/tracks.dart';

void toast(BuildContext context, String message, {bool error = false}) {
  final p = Palette.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: error ? Colors.white : p.paper, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: error ? Colors.white : p.paper))),
      ]),
      backgroundColor: error ? p.bad : p.ink,
    ));
}

String errorMessage(BuildContext context, Object error) {
  if (error is ApiException) {
    if (error.code == 'timeout') return context.t('errors.timeout');
    if (error.status == 0) return context.t('errors.network');
    if (error.status == 429) return context.t('errors.rate');
    if (error.code == 'program_not_found') return context.t('errors.program');
    if (error.status == 422) return context.t('errors.fix');
    if (error.status == 502 || error.status == 503 || error.status == 504) return context.t('errors.waking');
  }
  return context.t('errors.generic');
}

Future<bool> confirmDialog(BuildContext context, String message, String action, {bool danger = true}) async {
  final p = Palette.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(context.t('msg.confirmTitle')),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: p.muted),
          child: Text(context.t('act.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: danger ? p.bad : p.brass,
            foregroundColor: Colors.white,
            minimumSize: const Size(64, 44),
          ),
          child: Text(action),
        ),
      ],
    ),
  );
  return result == true;
}

/// Small uppercase label with a brass rule, used above section titles.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Palette.of(context).brass;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 22, height: 2, color: c),
      const SizedBox(width: 8),
      Flexible(
        child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.6)),
      ),
    ]);
  }
}

class SectionHead extends StatelessWidget {
  const SectionHead({super.key, this.eyebrow, required this.title, this.subtitle, this.trailing});
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 8)],
          Text(title, style: displayStyle(context, 21)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: TextStyle(color: p.muted, height: 1.6)),
          ],
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.actionLabel, this.onAction});
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle),
          child: Icon(icon, color: p.muted, size: 30),
        ),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: p.muted, height: 1.6)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    );
  }
}

/// Program or certificate code in the monospace face.
class CodeTag extends StatelessWidget {
  const CodeTag(this.code, {super.key, this.color, this.size = 12.5});
  final String code;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(code, textDirection: TextDirection.ltr, style: monoStyle(size: size, color: color ?? Palette.of(context).brass));
  }
}

class TrackTag extends StatelessWidget {
  const TrackTag(this.trackId, {super.key, this.color, this.short = false});
  final String trackId;
  final Color? color;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final t = trackOf(trackId);
    final lang = context.lang;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          short ? t.shortName(lang) : t.name(lang),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color ?? Palette.of(context).muted),
        ),
      ),
    ]);
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset('assets/images/logo.png', width: size, height: size, fit: BoxFit.cover),
    );
  }
}

/// A rounded surface card with a hairline border.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: color ?? p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Ruler ticks along the bottom edge of navy panels (the brand's signature detail).
class RulerPainter extends CustomPainter {
  RulerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = fade(color, 0.22)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = fade(color, 0.45)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 10) {
      final isMajor = (x / 10).round() % 5 == 0;
      final h = isMajor ? size.height : size.height * 0.5;
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - h), isMajor ? major : minor);
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter old) => old.color != color;
}

/// Colored status pill used in admin lists.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fade(color, 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fade(color, 0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

Color statusColor(BuildContext context, String status) {
  final p = Palette.of(context);
  switch (status) {
    case 'new':
    case 'unread':
      return p.brass;
    case 'contacted':
    case 'in_discussion':
    case 'proposal_sent':
      return p.info;
    case 'enrolled':
    case 'completed':
    case 'won':
      return p.ok;
    default:
      return p.muted;
  }
}

/// Horizontal list of selectable chips.
class ChoiceChips extends StatelessWidget {
  const ChoiceChips({super.key, required this.options, required this.selected, required this.onSelected, this.dots});
  final List<MapEntry<String, String>> options; // value -> label
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, Color>? dots;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = options[i];
          final on = o.key == selected;
          final dot = dots?[o.key];
          return Pressable2(
            onTap: () => onSelected(o.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? p.ink : p.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? p.ink : p.line, width: 1.4),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (dot != null) ...[
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                ],
                Text(o.value, style: TextStyle(color: on ? p.paper : p.muted, fontWeight: FontWeight.w600, fontSize: 13.5)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// Tap target that scales down while pressed (no ripple), for chips.
class Pressable2 extends StatefulWidget {
  const Pressable2({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<Pressable2> createState() => _Pressable2State();
}

class _Pressable2State extends State<Pressable2> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? 0.95 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}

/// Navy page header with ruler ticks, used at the top of tabs.
class NavyHeader extends StatelessWidget {
  const NavyHeader({super.key, required this.child, this.bottomPadding = 28});
  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.navy, p.navy2]),
      ),
      child: Stack(children: [
        Padding(padding: EdgeInsets.fromLTRB(20, top + 20, 20, bottomPadding), child: child),
        Positioned(left: 0, right: 0, bottom: 0, height: 12, child: CustomPaint(painter: RulerPainter(color: p.onNavy))),
      ]),
    );
  }
}
