import 'constants.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/dashboard_screen.dart';

void main() {
        runApp(const MyApp());
}

class MyApp extends StatelessWidget {
        const MyApp({super.key});

        @override
        Widget build(BuildContext context) {
                Future<bool> isRunningOnEmulator() async {
                        final deviceInfo = DeviceInfoPlugin();
                        final androidInfo = await deviceInfo.androidInfo;
                        return !androidInfo.isPhysicalDevice;
                }

                return FutureBuilder<bool>(
                        future: isRunningOnEmulator(),
                        builder: (context, snapshot) {
                                // Boolean pour basculer entre ConnectionScreen et DashboardScreen
                                //  Depend de l'environnement de développement
                                //  Si emulateur, on affiche le DashboardScreen
                                //  Si pas emulateur, on affiche le ConnectionScreen
                                final areWeInDevelopingMode = snapshot.data ?? false;

                                return MaterialApp(
                                        debugShowCheckedModeBanner: false,
                                        title: 'Glacier SMA',
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
                                                        onError: Colors.white
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

                                        home: areWeInDevelopingMode
                                                ? const DashboardScreen(flutterSerialCommunicationPlugin: null, isConnected: false, connectedDevices: [])
                                                : const ConnectionScreen()
                                );

                        }
                );
        }
}

//TODO afficher batterie status dynamiquement selon le voltage
//TODO bottom navigation bar ou possiblement slide menu
//TODO settings min max sensors value menu + messages de notification si dehors des limites
//TODO settings pour power les sensors
//TODO deplacer DEBUG switch dans settings menu
//TODO Internationalisation EN + FR
//TODO vérifier horizontal mode partout
//TODO rediger README au fur et à mesure

//TODO faire plus de TODOs :)