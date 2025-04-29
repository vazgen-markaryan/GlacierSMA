/// Point d'entrée de l'application Flutter Glacier SMA.
/// Configure l'apparence de l'app et détermine l'écran initial selon l'environnement (émulateur ou appareil physique).

import 'utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';

void main() {
        // Fonction principale qui démarre l'application Flutter
        runApp(const MyApp());
}

class MyApp extends StatelessWidget {
        const MyApp({super.key});

        @override
        Widget build(BuildContext context) {
                // Fonction interne pour détecter si l'app tourne sur un émulateur
                Future<bool> isRunningOnEmulator() async {
                        final deviceInfo = DeviceInfoPlugin();
                        final androidInfo = await deviceInfo.androidInfo;
                        return !androidInfo.isPhysicalDevice;
                }

                return FutureBuilder<bool>(
                        future: isRunningOnEmulator(),
                        builder: (context, snapshot) {
                                // Détermine si on est en mode développement (émulateur)
                                final areWeInDevelopingMode = snapshot.data ?? false;

                                return MaterialApp(
                                        debugShowCheckedModeBanner: false,
                                        title: 'Glacier SMA',

                                        // Définition du thème général de l'application (mode sombre)
                                        theme: ThemeData.dark().copyWith(
                                                primaryColor: primaryColor,
                                                scaffoldBackgroundColor: backgroundColor,
                                                canvasColor: secondaryColor,
                                                colorScheme: const ColorScheme.dark().copyWith(
                                                        primary: primaryColor,
                                                        secondary: secondaryColor,
                                                        surface: backgroundColor,
                                                        onPrimary: Colors.white,
                                                        onSecondary: Colors.white,
                                                        onSurface: Colors.white,
                                                        onError: Colors.red
                                                ),
                                                textTheme: ThemeData.dark().textTheme.apply(
                                                        bodyColor: Colors.white,
                                                        displayColor: Colors.white
                                                ),
                                                appBarTheme: const AppBarTheme(
                                                        backgroundColor: secondaryColor,
                                                        iconTheme: IconThemeData(color: Colors.white),
                                                        titleTextStyle: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 20,
                                                                fontWeight: FontWeight.bold
                                                        )
                                                ),
                                                elevatedButtonTheme: ElevatedButtonThemeData(
                                                        style: ElevatedButton.styleFrom(
                                                                backgroundColor: primaryColor,
                                                                foregroundColor: Colors.white,
                                                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                                        )
                                                ),
                                                snackBarTheme: SnackBarThemeData(
                                                        backgroundColor: secondaryColor,
                                                        contentTextStyle: const TextStyle(color: Colors.white),
                                                        actionTextColor: primaryColor
                                                )
                                        ),

                                        // Écran d'accueil selon le contexte : émulateur ou appareil réel
                                        home: areWeInDevelopingMode
                                                ? const DashboardScreen(plugin: null, isConnected: false, connectedDevices: [])
                                                : const ConnectionScreen()
                                );
                        }
                );
        }
}

// TODO's pour les futures améliorations de l'application :

// TODO Support multilingue (EN + FR)
// TODO Activer/désactiver manuellement les capteurs via paramètres
// TODO Sensor popup graph real time (ou pas popup mais autre page)
// TODO Créer des réglages pour les limites min/max des capteurs avec notifications

//Capture data
// TODO Déconnexion automatique en cas d'erreur fatale
// TODO afficher la version du commit à l'aide de git hash recu en message