// Kerangka: bottom-nav 5 + IndexedStack + back aman (ui.md §3, §6).
// Menu → Kebijakan/Kejadian nyata (push); Diplomasi layar nyata Fase 1.
import 'package:flutter/material.dart';

import '../models/country.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'diplomacy_screen.dart';
import 'economy_screen.dart';
import 'menu_screen.dart';
import 'resources_screen.dart';

class AppShell extends StatefulWidget {
  final Country country;
  const AppShell({super.key, required this.country});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  // Tab awal Ekonomi untuk deep-link dari Beranda (0 Ringkasan … 3 Perdagangan).
  int _economyTab = 0;

  void _openEconomy(int tab) => setState(() {
        _economyTab = tab.clamp(0, 3);
        _index = 1;
      });

  void _openDiplomacy() => setState(() => _index = 3);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
          country: widget.country,
          onOpenEconomy: _openEconomy,
          onOpenDiplomacy: _openDiplomacy),
      // Deep-link: ValueKey memaksa rebuild saat tab awal berubah dari Beranda.
      EconomyScreen(
          key: ValueKey('eco-$_economyTab'), initialTabIndex: _economyTab),
      const ResourcesScreen(),
      const DiplomacyScreen(),
      const MenuScreen(),
    ];

    const labels = ['Beranda', 'Ekonomi', 'Sumber Daya', 'Diplomasi', 'Menu'];
    const icons = [
      Icons.home_outlined,
      Icons.show_chart_rounded,
      Icons.inventory_2_outlined,
      Icons.public_rounded,
      Icons.menu_rounded,
    ];
    const activeIcons = [
      Icons.home_rounded,
      Icons.show_chart_rounded,
      Icons.inventory_2_rounded,
      Icons.public_rounded,
      Icons.menu_rounded,
    ];

    // Back aman: dari tab lain kembali ke Beranda dulu, bukan keluar aplikasi.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        backgroundColor: SovereignColors.deepNavy,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: pages),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: SizedBox(
            height: SovereignSpacing.bottomNavHeight + 12,
            child: NavigationBar(
              height: SovereignSpacing.bottomNavHeight,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: List.generate(5, (i) {
                return NavigationDestination(
                  icon: Icon(_index == i ? activeIcons[i] : icons[i]),
                  label: labels[i],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
