import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../widgets/motion.dart';
import 'account_screen.dart';
import 'admin_login_screen.dart';
import 'certificates_tab.dart';
import 'corporate_tab.dart';
import 'messages_tab.dart';
import 'overview_tab.dart';
import 'programs_admin_screen.dart';
import 'registrations_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);
  final _overviewKey = GlobalKey<OverviewTabState>();
  int _newRegs = 0;
  int _unread = 0;
  int _corpOpen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final state = AppScope.read(context);
    final ok = await state.restoreAdmin();
    if (!ok && mounted) {
      Navigator.of(context).pushReplacement(fadeThrough(const AdminLoginScreen()));
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onOverview(Map<String, dynamic> data) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    final reg = data['registrations'];
    final byStatus = reg is Map ? reg['byStatus'] : null;
    setState(() {
      _newRegs = byStatus is Map ? n(byStatus['new']) : 0;
      _unread = n(data['unreadMessages']);
      _corpOpen = n(data['corporateOpen']);
    });
  }

  void _refreshBadges() => _overviewKey.currentState?.reload();

  Widget _tab(String label, int badge) {
    return Tab(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: badge > 0
              ? Container(
                  key: ValueKey(badge),
                  margin: const EdgeInsetsDirectional.only(start: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: Palette.brassOnNavy, borderRadius: BorderRadius.circular(999)),
                  child: Text('$badge', style: const TextStyle(color: Color(0xFF1A1205), fontSize: 11.5, fontWeight: FontWeight.w700)),
                )
              : const SizedBox.shrink(key: ValueKey(0)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final onNavy = Palette.light.onNavy;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: p.navy,
        foregroundColor: onNavy,
        surfaceTintColor: Colors.transparent,
        title: Text(context.t('admin.title')),
        actions: [
          IconButton(
            tooltip: context.t('admin.programs'),
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(fadeThrough(const ProgramsAdminScreen())),
          ),
          IconButton(
            tooltip: context.t('admin.account'),
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => Navigator.of(context).push(fadeThrough(const AccountScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Palette.brassOnNavy,
          indicatorWeight: 3,
          labelColor: onNavy,
          unselectedLabelColor: Palette.light.onNavyMuted,
          dividerColor: Colors.transparent,
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            _tab(context.t('admin.overview'), 0),
            _tab(context.t('admin.registrations'), _newRegs),
            _tab(context.t('admin.messages'), _unread),
            _tab(context.t('admin.corporate'), _corpOpen),
            _tab(context.t('admin.certificates'), 0),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        OverviewTab(key: _overviewKey, onData: _onOverview, onOpenTab: (i) => _tabs.animateTo(i)),
        RegistrationsTab(onChanged: _refreshBadges),
        MessagesTab(onChanged: _refreshBadges),
        CorporateTab(onChanged: _refreshBadges),
        CertificatesTab(onChanged: _refreshBadges),
      ]),
    );
  }
}
