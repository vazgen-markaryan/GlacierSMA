import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

/// Barre de navigation du Dashboard (Accueil / Debug / Paramètres)
class BottomNavBar extends StatelessWidget {
        /// Index de l'onglet actuellement sélectionné
        final int selectedIndex;

        /// Callback appelé quand l'utilisateur change d'onglet
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

                        // Définition des 3 onglets
                        items: const[
                                BottomNavigationBarItem(
                                        icon: Icon(Icons.home),
                                        label: 'Accueil'
                                ),
                                BottomNavigationBarItem(
                                        icon: Icon(Icons.bug_report),
                                        label: 'Debug'
                                ),
                                BottomNavigationBarItem(
                                        icon: Icon(Icons.settings),
                                        label: 'Paramètres'
                                )
                        ],

                        // Gestion de l'état sélectionné
                        currentIndex: selectedIndex,
                        onTap: onItemTapped
                );
        }
}