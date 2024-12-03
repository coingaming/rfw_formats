import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<Map<String, dynamic>> routeConfigs;

  const ScaffoldWithNavBar({
    Key? key,
    required this.navigationShell,
    this.routeConfigs = const [],
  }) : super(key: key ?? const ValueKey<String>("ScaffoldWithNavBar"));

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    final List<BottomNavigationBarItem> dynamicItems = [];

    for (final config in routeConfigs) {
      if (config['isShellRoute'] == true) {
        final iconHexStr = config['iconHex']?.toString();
        final iconHex = iconHexStr != null ? int.tryParse(iconHexStr) : null;
        final label = config['label'] as String?;
        final fontFamily = config['fontFamily'] as String?;

        if (iconHex != null && label != null) {
          dynamicItems.add(
            BottomNavigationBarItem(
              icon: Icon(
                IconData(
                  iconHex,
                  fontFamily: fontFamily ?? 'MaterialIcons',
                ),
              ),
              label: label,
            ),
          );
        }
      }
    }

    // Prepend dynamic items to existing ones
    return [
      ...dynamicItems,
      const BottomNavigationBarItem(
          icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: _buildNavigationItems(),
        onTap: _onTap,
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
      ),
    );
  }
}
