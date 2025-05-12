import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

/// Barre de navigation du Dashboard
class BottomNavBar extends StatelessWidget {
        // Index de l'onglet actuellement sélectionné
        final int selectedIndex;
        // Callback appelé quand l'utilisateur change d'onglet
        final ValueChanged<int> onItemTapped;

        const BottomNavBar({
                Key? key,
                required this.selectedIndex,
                required this.onItemTapped
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return BottomNavigationBar(
                        backgroundColor: secondaryColor,
                        selectedItemColor: primaryColor,
                        unselectedItemColor: Colors.white70,
                        type: BottomNavigationBarType.fixed,
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),

                        items: [
                                BottomNavigationBarItem(
                                        icon: const Icon(Icons.home),
                                        label: tr('dashboard.sensors.navbar.home')
                                ),
                                BottomNavigationBarItem(
                                        icon: const Icon(Icons.bug_report),
                                        label: tr('dashboard.sensors.navbar.debug')
                                ),
                                BottomNavigationBarItem(
                                        icon: const Icon(Icons.tune),
                                        label: tr('dashboard.sensors.navbar.config')
                                ),
                                BottomNavigationBarItem(
                                        icon: const Icon(Icons.settings),
                                        label: tr('dashboard.sensors.navbar.settings')
                                )
                        ],

                        currentIndex: selectedIndex,
                        onTap: onItemTapped
                );
        }
}