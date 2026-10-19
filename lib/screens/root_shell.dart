import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../widgets/motion.dart';
import 'contact_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'programs_screen.dart';
import 'verify_screen.dart';

/// Bottom-navigation shell. Tabs keep their state; switching cross-fades.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  final CatalogFilter _filter = CatalogFilter();

  late final AnimationController _switch =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  late final Animation<double> _curve = CurvedAnimation(parent: _switch, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero).animate(_curve);

  void _go(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    if (reduceMotion(context)) {
      _switch.value = 1;
    } else {
      _switch.forward(from: 0);
    }
  }

  void _openPrograms([String? track]) {
    _filter.setTrack(track);
    _go(1);
  }

  @override
  void dispose() {
    _switch.dispose();
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position: _slide,
            child: IndexedStack(index: _index, children: [
              HomeScreen(onOpenPrograms: _openPrograms, onOpenVerify: () => _go(2)),
              ProgramsScreen(filter: _filter),
              const VerifyScreen(),
              const ContactScreen(),
              const MoreScreen(),
            ]),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          animationDuration: const Duration(milliseconds: 500),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: context.t('nav.home')),
            NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school_rounded), label: context.t('nav.programs')),
            NavigationDestination(icon: const Icon(Icons.verified_user_outlined), selectedIcon: const Icon(Icons.verified_user_rounded), label: context.t('nav.verify')),
            NavigationDestination(icon: const Icon(Icons.call_outlined), selectedIcon: const Icon(Icons.call_rounded), label: context.t('nav.contact')),
            NavigationDestination(icon: const Icon(Icons.more_horiz_rounded), selectedIcon: const Icon(Icons.more_horiz_rounded), label: context.t('nav.more')),
          ],
        ),
      ),
    );
  }
}
