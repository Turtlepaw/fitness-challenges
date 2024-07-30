import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class CustomNavigationBar extends StatelessWidget {
  final GoRouterState? state;

  const CustomNavigationBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      destinations: const [
        NavigationDestination(
          selectedIcon: Icon(Symbols.home_rounded),
          icon: Icon(Symbols.home_rounded, fill: 0),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Badge(child: Icon(Symbols.settings_rounded)),
          icon: Badge(child: Icon(Symbols.settings_rounded, fill: 0)),
          label: 'Settings',
        ),
      ],
      selectedIndex: switch (state?.fullPath) {
        "/home" => 0,
        "/settings" => 1,
        _ => 0
      },
      onDestinationSelected: (index) {
        if (index == 0) {
          context.go('/home');
        } else if (index == 1) {
          context.go('/settings');
        }
      },
    );
  }
}
