import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/tracks.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'admin_common.dart';

/// Dashboard: KPI tiles, status breakdown, top programs and a 30-day chart.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.onData, required this.onOpenTab});

  /// Reports the latest overview so the shell can show badge counts.
  final ValueChanged<Map<String, dynamic>> onData;

  /// Jump to another admin tab (index).
  final ValueChanged<int> onOpenTab;

  @override
  State<OverviewTab> createState() => OverviewTabState();
}

class OverviewTabState extends State<OverviewTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reload();
    });
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppScope.read(context).api.get('/admin/overview');
      if (!mounted) return;
      final map = Map<String, dynamic>.from(data as Map);
      setState(() => _data = map);
      widget.onData(map);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.status == 401) {
        handleAdminError(context, e);
        return;
      }
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _n(dynamic v) => v is num ? v.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = Palette.of(context);
    final data = _data;

    if (data == null) {
      if (_error != null) {
        return ListView(children: [
          EmptyState(icon: Icons.cloud_off_rounded, text: errorMessage(context, _error!), actionLabel: context.t('act.retry'), onAction: reload),
        ]);
      }
      return GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: List.generate(6, (_) => const Skeleton(height: 100)),
      );
    }

    final reg = Map<String, dynamic>.from((data['registrations'] as Map?) ?? const {});
    final byStatus = Map<String, dynamic>.from((reg['byStatus'] as Map?) ?? const {});
    final daily = ((reg['daily'] as List?) ?? const []).whereType<Map>().toList();
    final top = ((reg['topPrograms'] as List?) ?? const []).whereType<Map>().toList();
    final lang = context.lang;

    final tiles = <_Kpi>[
      _Kpi(context.t('kpi.registrations'), _n(reg['total']), sub: context.t('kpi.lastWeek', {'n': _n(reg['lastWeek'])}), tab: 1),
      _Kpi(context.t('kpi.new'), _n(byStatus['new']), attention: _n(byStatus['new']) > 0, tab: 1),
      _Kpi(context.t('kpi.unread'), _n(data['unreadMessages']), attention: _n(data['unreadMessages']) > 0, tab: 2),
      _Kpi(context.t('kpi.corporate'), _n(data['corporateOpen']), attention: _n(data['corporateOpen']) > 0, tab: 3),
      _Kpi(context.t('kpi.certificates'), _n(data['certificates']), tab: 4),
      _Kpi(context.t('kpi.programs'), _n(data['programsActive'])),
    ];

    return RefreshIndicator(
      color: p.brass,
      onRefresh: reload,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
        AnimatedOpacity(
          opacity: _loading ? 0.6 : 1,
          duration: const Duration(milliseconds: 200),
          child: LayoutBuilder(builder: (context, box) {
            final w = (box.maxWidth - 12) / 2;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (var i = 0; i < tiles.length; i++)
                SizedBox(
                  width: w,
                  child: Reveal(
                    delay: Duration(milliseconds: 50 * i),
                    child: _KpiTile(kpi: tiles[i], onTap: tiles[i].tab == null ? null : () => widget.onOpenTab(tiles[i].tab!)),
                  ),
                ),
            ]);
          }),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: const Duration(milliseconds: 250),
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('overview.daily'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              SizedBox(height: 170, child: _DailyChart(daily: daily, lang: lang)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Reveal(
          delay: const Duration(milliseconds: 320),
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('overview.status'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              _StatusBar(counts: {for (final s in registrationStatuses) s: _n(byStatus[s])}),
              const SizedBox(height: 14),
              Wrap(spacing: 16, runSpacing: 8, children: [
                for (final s in registrationStatuses)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _statusShade(context, s), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 6),
                    Text('${context.t('rstatus.$s')}  ', style: const TextStyle(fontSize: 13)),
                    Text(fmtNum(_n(byStatus[s])), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Reveal(
          delay: const Duration(milliseconds: 390),
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('overview.top'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              if (top.isEmpty)
                Text(context.t('overview.none'), style: TextStyle(color: p.muted))
              else
                ..._topRows(context, top, lang),
            ]),
          ),
        ),
      ]),
    );
  }

  List<Widget> _topRows(BuildContext context, List<Map> top, String lang) {
    final p = Palette.of(context);
    final max = top.map((e) => _n(e['n'])).fold<int>(1, math.max);
    return [
      for (var i = 0; i < top.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CodeTag((top[i]['code'] ?? '').toString()),
              const SizedBox(width: 8),
              Expanded(
                child: Text(Bi.from(top[i]['title']).pick(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
              ),
              Text(fmtNum(_n(top[i]['n'])), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            _GrowBar(fraction: _n(top[i]['n']) / max, color: p.brass, track: p.surface2, delay: i * 80),
          ]),
        ),
    ];
  }
}

Color _statusShade(BuildContext context, String s) {
  final p = Palette.of(context);
  switch (s) {
    case 'new':
      return p.brass;
    case 'contacted':
      return p.info;
    case 'enrolled':
      return p.ok;
    case 'completed':
      return const Color(0xFF5B8C6E);
    default:
      return p.line;
  }
}

class _Kpi {
  _Kpi(this.label, this.value, {this.sub, this.attention = false, this.tab});
  final String label;
  final int value;
  final String? sub;
  final bool attention;
  final int? tab;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi, this.onTap});
  final _Kpi kpi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Pressable(
      child: Panel(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kpi.label, maxLines: 2, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.3)),
          const SizedBox(height: 6),
          CountUp(
            value: kpi.value,
            duration: const Duration(milliseconds: 1000),
            style: displayStyle(context, 26, color: kpi.attention ? p.brass : p.ink, height: 1.1),
          ),
          if (kpi.sub != null) ...[
            const SizedBox(height: 4),
            Text(kpi.sub!, style: TextStyle(color: p.muted, fontSize: 11.5)),
          ],
        ]),
      ),
    );
  }
}

/// Horizontal bar that grows to [fraction] after [delay] ms.
class _GrowBar extends StatelessWidget {
  const _GrowBar({required this.fraction, required this.color, required this.track, this.delay = 0});
  final double fraction;
  final Color color;
  final Color track;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 7,
        color: track,
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0).toDouble()),
          duration: reduce ? Duration.zero : Duration(milliseconds: 900 + delay),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999))),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final reduce = reduceMotion(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Container(
            color: p.surface2,
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: total == 0 ? 0 : t,
              child: Row(children: [
                for (final e in counts.entries)
                  if (e.value > 0) Expanded(flex: e.value, child: Container(color: _statusShade(context, e.key))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.daily, required this.lang});
  final List<Map> daily;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final byDay = <String, int>{
      for (final d in daily) (d['date'] ?? '').toString(): (d['n'] is num) ? (d['n'] as num).toInt() : 0,
    };
    final today = DateTime.now();
    final days = [
      for (var i = 29; i >= 0; i--) DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
    ];
    final values = [for (final d in days) byDay[isoDay(d)] ?? 0];
    final reduce = reduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          values: values,
          firstLabel: fmtDate(days.first, lang),
          lastLabel: fmtDate(days.last, lang),
          t: t,
          bar: p.brass,
          grid: p.line,
          text: p.muted,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.firstLabel,
    required this.lastLabel,
    required this.t,
    required this.bar,
    required this.grid,
    required this.text,
  });

  final List<int> values;
  final String firstLabel;
  final String lastLabel;
  final double t;
  final Color bar;
  final Color grid;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0;
    const bottom = 20.0;
    final w = size.width - left;
    final h = size.height - bottom;
    final maxV = values.fold<int>(0, math.max);
    final top = maxV <= 4 ? 4 : ((maxV + 3) ~/ 4) * 4;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final y = h - h * k / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      _label(canvas, '${top * k ~/ 4}', Offset(0, y - 7), 22, TextAlign.right);
    }

    final bw = w / values.length;
    final barPaint = Paint()..color = bar;
    for (var i = 0; i < values.length; i++) {
      // Each bar starts slightly after the previous one.
      final local = ((t * 1.6) - i / values.length * 0.6).clamp(0.0, 1.0).toDouble();
      final bh = h * values[i] / top * Curves.easeOutCubic.transform(local);
      if (bh <= 0) continue;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left + i * bw + bw * 0.18, h - bh, bw * 0.64, bh),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);
    }

    _label(canvas, firstLabel, Offset(left, h + 5), 120, TextAlign.left);
    _label(canvas, lastLabel, Offset(size.width - 120, h + 5), 120, TextAlign.right);
  }

  void _label(Canvas canvas, String s, Offset at, double width, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: text, fontSize: 10.5)),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.t != t || old.values != values || old.bar != bar;
}
