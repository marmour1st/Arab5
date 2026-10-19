import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_shell.dart';
import 'corporate_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = Palette.of(context);
    final top = MediaQuery.of(context).padding.top;

    Widget label(String key) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(context.t(key), style: TextStyle(color: p.muted, fontWeight: FontWeight.w700, fontSize: 13)),
        );

    return ListView(padding: EdgeInsets.fromLTRB(20, top + 20, 20, 32), children: [
      Reveal(
        child: Row(children: [
          const BrandMark(size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.t('app.name'), style: displayStyle(context, 20)),
              Text(context.t('app.sub'), style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 28),

      Reveal(delay: const Duration(milliseconds: 60), child: label('more.language')),
      Reveal(
        delay: const Duration(milliseconds: 60),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'ar', label: Text('العربية')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {state.lang},
            onSelectionChanged: (s) => state.setLang(s.first),
          ),
        ),
      ),
      const SizedBox(height: 20),

      Reveal(delay: const Duration(milliseconds: 120), child: label('more.theme')),
      Reveal(
        delay: const Duration(milliseconds: 120),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(context.t('more.themeSystem'))),
              ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(context.t('more.themeLight'))),
              ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(context.t('more.themeDark'))),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.setThemeMode(s.first),
          ),
        ),
      ),
      const SizedBox(height: 28),

      Reveal(
        delay: const Duration(milliseconds: 180),
        child: _Tile(
          icon: Icons.apartment_outlined,
          title: context.t('more.corporate'),
          onTap: () => Navigator.of(context).push(fadeThrough(const CorporateScreen())),
        ),
      ),
      Reveal(
        delay: const Duration(milliseconds: 220),
        child: _Tile(
          icon: Icons.public_rounded,
          title: context.t('more.website'),
          external: true,
          onTap: () => openExternal(context, Uri.parse(AppConfig.siteUrl)),
        ),
      ),
      Reveal(
        delay: const Duration(milliseconds: 260),
        child: _Tile(
          icon: Icons.facebook,
          title: context.t('more.facebook'),
          external: true,
          onTap: () => openExternal(context, Uri.parse(AppConfig.facebookUrl)),
        ),
      ),
      const SizedBox(height: 20),

      Reveal(delay: const Duration(milliseconds: 300), child: label('more.staff')),
      Reveal(
        delay: const Duration(milliseconds: 300),
        child: _Tile(
          icon: Icons.admin_panel_settings_outlined,
          title: context.t(state.isAdmin ? 'more.openAdmin' : 'more.staffLogin'),
          highlight: state.isAdmin,
          onTap: () => Navigator.of(context).push(
            fadeThrough(state.isAdmin ? const AdminShell() : const AdminLoginScreen()),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Center(
        child: Text(context.t('more.version', {'v': AppConfig.version}), style: TextStyle(color: p.muted, fontSize: 12)),
      ),
    ]);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap, this.external = false, this.highlight = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool external;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        child: Panel(
          onTap: onTap,
          color: highlight ? p.brassSoft : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, color: p.brass),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Icon(external ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded, size: 18, color: p.muted),
          ]),
        ),
      ),
    );
  }
}
