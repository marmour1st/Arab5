import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/program_card.dart';
import '../widgets/track_dial.dart';
import 'corporate_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenPrograms, required this.onOpenVerify});

  final void Function([String? track]) onOpenPrograms;
  final VoidCallback onOpenVerify;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final featured = state.programs.where((x) => x.featured).toList();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _Hero(onOpenPrograms: onOpenPrograms)),

      // Featured carousel
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 12, 14),
          child: SectionHead(
            title: context.t('home.featured'),
            trailing: TextButton(onPressed: () => onOpenPrograms(), child: Text(context.t('home.seeAll'))),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 228,
          child: featured.isEmpty
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    SizedBox(width: 280, child: Skeleton(height: 228)),
                    SizedBox(width: 12),
                    SizedBox(width: 280, child: Skeleton(height: 228)),
                  ],
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 284,
                    child: Reveal(
                      delay: Duration(milliseconds: 90 * i),
                      offset: 18,
                      child: ProgramCard(program: featured[i], heroPrefix: 'home', compact: true),
                    ),
                  ),
                ),
        ),
      ),

      // How it works
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHead(eyebrow: context.t('home.howEyebrow'), title: context.t('home.howTitle')),
            const SizedBox(height: 20),
            for (var i = 1; i <= 5; i++)
              Reveal(delay: Duration(milliseconds: 70 * i), child: _Step(number: i, last: i == 5)),
          ]),
        ),
      ),

      // Why us
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHead(eyebrow: context.t('home.whyEyebrow'), title: context.t('home.whyTitle')),
            const SizedBox(height: 18),
            const _FeatureGrid(),
          ]),
        ),
      ),

      // Calls to action
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: _CtaCard(
            icon: Icons.verified_outlined,
            title: context.t('home.verifyTitle'),
            body: context.t('home.verifyBody'),
            action: context.t('home.verifyCta'),
            onTap: onOpenVerify,
            navy: true,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: _CtaCard(
            icon: Icons.apartment_outlined,
            title: context.t('home.corpTitle'),
            body: context.t('home.corpBody'),
            action: context.t('home.corpCta'),
            onTap: () => Navigator.of(context).push(fadeThrough(const CorporateScreen())),
          ),
        ),
      ),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onOpenPrograms});
  final void Function([String? track]) onOpenPrograms;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.of(context);
    final top = MediaQuery.of(context).padding.top;
    final onNavy = Palette.light.onNavy;
    final onNavyMuted = Palette.light.onNavyMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.navy, p.navy2]),
      ),
      child: Stack(children: [
        Positioned(
          top: -120,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [fade(Palette.brassOnNavy, 0.16), fade(Palette.brassOnNavy, 0)]),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top bar
            Row(children: [
              const BrandMark(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.t('app.name'), style: displayStyle(context, 16, color: onNavy, height: 1.2)),
                  Text(context.t('app.sub'),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onNavyMuted, fontSize: 11.5)),
                ]),
              ),
              _RoundButton(
                onTap: () => state.setLang(state.lang == 'ar' ? 'en' : 'ar'),
                child: Text(state.lang == 'ar' ? 'EN' : 'ع', style: TextStyle(color: onNavy, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              _RoundButton(
                onTap: () => state.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween<double>(begin: 0.6, end: 1).animate(anim),
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    key: ValueKey(isDark),
                    color: onNavy,
                    size: 20,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 30),
            Reveal(child: Eyebrow(context.t('hero.eyebrow'), color: Palette.brassOnNavy)),
            const SizedBox(height: 14),
            Reveal(
              delay: const Duration(milliseconds: 90),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: context.t('hero.title1')),
                  TextSpan(text: context.t('hero.titleEm'), style: const TextStyle(color: Palette.brassOnNavy)),
                  TextSpan(text: context.t('hero.title2')),
                ]),
                style: displayStyle(context, 31, color: onNavy, weight: FontWeight.w800, height: 1.3),
              ),
            ),
            const SizedBox(height: 14),
            Reveal(
              delay: const Duration(milliseconds: 180),
              child: Text(context.t('hero.lead'), style: TextStyle(color: onNavyMuted, fontSize: 15.5, height: 1.75)),
            ),
            const SizedBox(height: 24),
            Reveal(
              delay: const Duration(milliseconds: 270),
              child: Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  onPressed: () => onOpenPrograms(),
                  style: FilledButton.styleFrom(backgroundColor: Palette.brassOnNavy, foregroundColor: const Color(0xFF1A1205)),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(context.t('hero.cta1')),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(fadeThrough(const CorporateScreen())),
                  style: OutlinedButton.styleFrom(foregroundColor: onNavy, side: BorderSide(color: fade(onNavy, 0.35), width: 1.4)),
                  child: Text(context.t('hero.cta2')),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 360),
              child: Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: fade(onNavy, 0.16)))),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _Stat(value: state.trainees, prefix: '+', label: context.t('stats.trainees'))),
                    Expanded(child: _Stat(value: state.programs.length, label: context.t('stats.programs'))),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _Stat(value: 7, label: context.t('stats.tracks'))),
                    Expanded(child: _Stat(value: state.years, prefix: '+', label: context.t('stats.years'))),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: TrackDial(
                  counts: state.trackCounts,
                  total: state.programs.length,
                  lang: state.lang,
                  allLabel: context.t('dial.all'),
                  onSelect: (track) => Future.delayed(const Duration(milliseconds: 650), () => onOpenPrograms(track)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(child: Text(context.t('dial.hint'), style: TextStyle(color: onNavyMuted, fontSize: 12.5))),
          ]),
        ),
        Positioned(left: 0, right: 0, bottom: 0, height: 14, child: CustomPaint(painter: RulerPainter(color: onNavy))),
      ]),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onNavy = Palette.light.onNavy;
    return Pressable(
      child: Material(
        color: fade(onNavy, 0.06),
        shape: CircleBorder(side: BorderSide(color: fade(onNavy, 0.22))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: SizedBox(width: 42, height: 42, child: Center(child: child))),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.prefix = ''});
  final int value;
  final String label;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CountUp(value: value, prefix: prefix, style: displayStyle(context, 26, color: Palette.light.onNavy, height: 1.1)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Palette.light.onNavyMuted, fontSize: 12.5)),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.last});
  final int number;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 40,
          child: Column(children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.brassSoft, shape: BoxShape.circle, border: Border.all(color: fade(p.brass, 0.4))),
              child: Text(number.toString().padLeft(2, '0'), style: monoStyle(size: 12, color: p.brass, weight: FontWeight.w600)),
            ),
            if (!last) Expanded(child: Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 4), color: p.line)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 22, top: 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('step$number.title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              const SizedBox(height: 4),
              Text(context.t('step$number.body'), style: TextStyle(color: p.muted, height: 1.6, fontSize: 13.5)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.workspace_premium_outlined, 'feat.certs'),
      (Icons.groups_outlined, 'feat.trainers'),
      (Icons.science_outlined, 'feat.labs'),
      (Icons.support_agent_outlined, 'feat.follow'),
    ];
    Widget cell(int i) => Expanded(
          child: Reveal(
            delay: Duration(milliseconds: 80 * i),
            child: _Feature(icon: items[i].$1, keyBase: items[i].$2),
          ),
        );
    return Column(children: [
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cell(0), const SizedBox(width: 12), cell(1)])),
      const SizedBox(height: 12),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cell(2), const SizedBox(width: 12), cell(3)])),
    ]);
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.keyBase});
  final IconData icon;
  final String keyBase;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: p.brass, size: 28),
        const SizedBox(height: 10),
        Text(context.t(keyBase), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        const SizedBox(height: 4),
        Text(context.t('${keyBase}Body'), style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.55)),
      ]),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
    this.navy = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  final bool navy;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final fg = navy ? Palette.light.onNavy : p.ink;
    final muted = navy ? Palette.light.onNavyMuted : p.muted;
    final accent = navy ? Palette.brassOnNavy : p.brass;
    return Pressable(
      child: Material(
        color: navy ? p.navy : p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: navy ? p.navy : p.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: fade(accent, 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15.5)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(action, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
