import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/global_state.dart';

/// Barre de navigation du Dashboard
class BottomNavBar extends StatelessWidget {
        final int selectedIndex;
        final ValueChanged<int> onItemTapped;

        const BottomNavBar({
                Key? key,
                required this.selectedIndex,
                required this.onItemTapped
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                final mode = GlobalConnectionState.instance.currentMode;

                // Génère dynamiquement les items selon le mode
                final items = [
                        BottomNavigationBarItem(
                                icon: const Icon(Icons.home),
                                label: tr('home.navbar.home')
                        ),

                        BottomNavigationBarItem(
                                icon: const Icon(Icons.bug_report),
                                label: tr('home.navbar.debug')
                        ),

                        BottomNavigationBarItem(
                                icon: const Icon(Icons.tune),
                                label: tr('home.navbar.config')
                        ),

                        if (mode == ConnectionMode.usb)
                        BottomNavigationBarItem(
                                icon: const Icon(Icons.eco),
                                label: tr('home.navbar.test')
                        ),

                        BottomNavigationBarItem(
                                icon: const Icon(Icons.settings),
                                label: tr('home.navbar.settings')
                        )
                ];

                return BottomNavigationBar(
                        backgroundColor: secondaryColor,
                        selectedItemColor: primaryColor,
                        unselectedItemColor: Colors.white70,
                        type: BottomNavigationBarType.fixed,
                        showSelectedLabels: true,
                        showUnselectedLabels: true,
                        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        items: items,
                        currentIndex: selectedIndex,
                        onTap: onItemTapped
                );
        }
}