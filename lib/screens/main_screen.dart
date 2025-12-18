import 'package:flutter/material.dart';
import 'package:smart_greenhouse/l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'plant_info_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ShopScreen(),
    const PlantInfoScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Added to support >3 items
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: AppLocalizations.of(context).dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: AppLocalizations.of(context).shop,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article),
            label: AppLocalizations.of(context).news,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context).settings,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
