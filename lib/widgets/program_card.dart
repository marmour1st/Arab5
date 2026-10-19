import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../screens/program_detail_screen.dart';
import 'common.dart';
import 'motion.dart';

class ProgramCard extends StatelessWidget {
  const ProgramCard({super.key, required this.program, required this.heroPrefix, this.compact = false});

  final Program program;

  /// Hero tags must be unique on a screen; the home carousel and the catalog use different prefixes.
  final String heroPrefix;

  /// Fixed-height variant for horizontal carousels.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    final heroTag = '$heroPrefix-${program.code}';
    final title = program.title.pick(lang);

    final meta = Wrap(spacing: 14, runSpacing: 6, children: [
      _Meta(icon: Icons.schedule_rounded, text: context.t('catalog.hours', {'n': program.hours}), strong: true),
      _Meta(icon: Icons.signal_cellular_alt_rounded, text: context.t('level.${program.level}')),
      _Meta(icon: Icons.devices_outlined, text: program.modes.map((m) => context.t('mode.$m')).join(' · ')),
    ]);

    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TrackTag(program.track)),
        const SizedBox(width: 8),
        if (program.featured)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: p.brassSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(context.t('catalog.featured'), style: TextStyle(color: p.brass, fontSize: 11.5, fontWeight: FontWeight.w700)),
          )
        else
          CodeTag(program.code),
      ]),
      const SizedBox(height: 10),
      Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, height: 1.35, color: p.ink),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        program.summary.pick(lang),
        maxLines: compact ? 2 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.55),
      ),
      if (compact) const Spacer() else const SizedBox(height: 12),
      Container(height: 1, color: p.line, margin: const EdgeInsets.only(bottom: 10)),
      meta,
    ]);

    return Pressable(
      child: Panel(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.of(context).push(fadeThrough(ProgramDetailScreen(program: program, heroTag: heroTag))),
        child: body,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.strong = false});
  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: p.muted),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12.5, color: strong ? p.ink : p.muted, fontWeight: strong ? FontWeight.w700 : FontWeight.w500)),
    ]);
  }
}
