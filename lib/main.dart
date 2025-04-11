import 'constants.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/dashboard_screen.dart';

void main() {
        runApp(const MyApp());
}

class MyApp extends StatelessWidget {
        const MyApp({super.key});

        @override
        Widget build(BuildContext context) {
                /// Boolean pour basculer entre ConnectionScreen et DashboardScreen
                /// DEFAULT: FALSE
                /// Si true, bypass le ConnectionScreen et affiche le DashboardScreen (pour le développement seulement)
                /// Si false, affiche le ConnectionScreen (ce qui est le comportement par défaut)
                bool areWeInDevelopingMode = false;

                return MaterialApp(
                        debugShowCheckedModeBanner: false,
                        title: 'Glacier SMA',
                        theme: ThemeData.dark().copyWith(
                                scaffoldBackgroundColor: backgroundColor,
                                textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
                                canvasColor: secondaryColor
                        ),

                        /// Basculer entre ConnectionScreen et DashboardScreen
                        home: areWeInDevelopingMode
                                ? const DashboardScreen(flutterSerialCommunicationPlugin: null, isConnected: false, connectedDevices: [])
                                : const ConnectionScreen()
                );
        }
}