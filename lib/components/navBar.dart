import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../utils/health.dart';

class CustomNavigationBar extends StatelessWidget {
  final GoRouterState? state;

  const CustomNavigationBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthManager>(context);

    return NavigationBar(
      destinations: [
        const NavigationDestination(
          selectedIcon: Icon(Symbols.home_rounded),
          icon: Icon(Symbols.home_rounded, fill: 0),
          label: 'Home',
        ),
        const NavigationDestination(
          selectedIcon: Icon(Symbols.people_rounded),
          icon: Icon(Symbols.people_rounded, fill: 0),
          label: 'Community',
        ),
        NavigationDestination(
          selectedIcon: const Icon(Symbols.settings_rounded),
          icon: health.isConnected
              ? const Icon(Symbols.settings_rounded, fill: 0)
              : const Badge(child: Icon(Symbols.settings_rounded, fill: 0)),
          label: 'Settings',
        ),
      ],
      selectedIndex: switch (state?.fullPath) {
        "/home" => 0,
        "/community" => 1,
        "/settings" => 2,
        _ => 0
      },
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go('/home');
        } else if (index == 1) {
          context.go('/community');
        } else if(index == 2){
          context.go('/settings');
        }
      },
    );
  }
}
