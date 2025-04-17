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

                                /// Boolean pour basculer entre ConnectionScreen et DashboardScreen
                                ///  Depend de l'environnement de développement
                                ///  Si emulateur, on affiche le DashboardScreen
                                ///  Si pas emulateur, on affiche le ConnectionScreen
                                final areWeInDevelopingMode = snapshot.data ?? false;

                                return MaterialApp(
                                        debugShowCheckedModeBanner: false,
                                        title: 'Glacier SMA',
                                        theme: ThemeData.dark().copyWith(
                                                scaffoldBackgroundColor: backgroundColor,
                                                textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
                                                canvasColor: secondaryColor
                                        ),
                                        home: areWeInDevelopingMode
                                                ? const DashboardScreen(flutterSerialCommunicationPlugin: null, isConnected: false, connectedDevices: [])
                                                : const ConnectionScreen()
                                );
                        }
                );
        }
}