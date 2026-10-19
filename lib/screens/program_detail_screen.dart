import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'registration_sheet.dart';

class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key, required this.program, required this.heroTag});

  final Program program;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lang = context.lang;
    final outcomes = program.outcomes(lang);
    final top = MediaQuery.of(context).padding.top;
    final onNavy = Palette.light.onNavy;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 300,
          backgroundColor: p.navy,
          foregroundColor: onNavy,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            stretchModes: const [StretchMode.zoomBackground],
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.navy, p.navy2]),
              ),
              child: Stack(children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 60, 20, 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(
                        child: Row(children: [
                          CodeTag(program.code, color: Palette.brassOnNavy, size: 13),
                          const SizedBox(width: 14),
                          Flexible(child: TrackTag(program.track, color: Palette.light.onNavyMuted)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Hero(
                        tag: heroTag,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            program.title.pick(lang),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: displayStyle(context, 23, color: onNavy, height: 1.35),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Reveal(
                        delay: const Duration(milliseconds: 150),
                        child: Row(children: [
                          Expanded(child: _Fact(label: context.t('program.hours'), value: '${program.hours}')),
                          const SizedBox(width: 8),
                          Expanded(child: _Fact(label: context.t('program.level'), value: context.t('level.${program.level}'))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Fact(
                              label: context.t('program.modes'),
                              value: program.modes.map((m) => context.t('mode.$m')).join(' · '),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                Positioned(left: 0, right: 0, bottom: 0, height: 12, child: CustomPaint(painter: RulerPainter(color: onNavy))),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          sliver: SliverList.list(children: [
            Reveal(
              delay: const Duration(milliseconds: 120),
              child: Text(program.summary.pick(lang), style: const TextStyle(fontSize: 16, height: 1.75)),
            ),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 180),
              child: Text(context.t('program.outcomes'), style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < outcomes.length; i++)
              Reveal(
                delay: Duration(milliseconds: 240 + i * 80),
                offset: 12,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: p.brassSoft, shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded, size: 16, color: p.brass),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(outcomes[i], style: const TextStyle(fontSize: 15, height: 1.6))),
                  ]),
                ),
              ),
            const SizedBox(height: 22),
            Reveal(
              delay: Duration(milliseconds: 260 + outcomes.length * 80),
              child: Panel(
                color: p.surface2,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.groups_outlined, color: p.brass, size: 20),
                    const SizedBox(width: 8),
                    Text(context.t('program.audience'), style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(program.audience.pick(lang), style: const TextStyle(fontSize: 15, height: 1.6)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(color: p.paper, border: Border(top: BorderSide(color: p.line))),
          child: Reveal(
            delay: const Duration(milliseconds: 300),
            offset: 30,
            child: FilledButton.icon(
              onPressed: () => showRegistrationSheet(context, program),
              icon: const Icon(Icons.how_to_reg_outlined),
              label: Text(context.t('program.register')),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onNavy = Palette.light.onNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fade(onNavy, 0.18)),
        color: fade(onNavy, 0.04),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Palette.light.onNavyMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onNavy, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}
