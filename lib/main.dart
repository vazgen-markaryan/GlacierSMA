/// Point d'entrée de l'application Flutter Glacier SMA.
/// Configure l'apparence de l'app et détermine l'écran initial selon l'environnement (émulateur ou appareil physique).

import 'utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';

Future<void> main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await EasyLocalization.ensureInitialized();

        // Détecte si on tourne sur un émulateur Android
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final runningOnEmulator = !androidInfo.isPhysicalDevice;

        runApp(
                EasyLocalization(
                        supportedLocales: const[Locale('en'), Locale('fr'), Locale('es')],
                        path: 'assets/translations',
                        fallbackLocale: const Locale('fr'),
                        saveLocale: true,
                        useOnlyLangCode: true,
                        child: MyApp(isEmulator: runningOnEmulator)
                )
        );
}

class MyApp extends StatelessWidget {
        final bool isEmulator;
        const MyApp({super.key, required this.isEmulator});

        @override
        Widget build(BuildContext context) {
                return MaterialApp(
                        debugShowCheckedModeBanner: false,
                        title: 'Glacier SMA', // Pas un titre affiché dans l'app. C'est pour le nom de l'application dans le système d'exploitation

                        // Internationalisation
                        locale: context.locale,
                        supportedLocales: context.supportedLocales,
                        localizationsDelegates: context.localizationDelegates,

                        // Thème sombre personnalisé
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

                        // Écran d'accueil selon l'environnement
                        home: isEmulator
                                ? const Home_Screen(plugin: null, isConnected: false, connectedDevices: [])
                                : const ConnectionScreen()
                );
        }
}

// TODO's pour les futures améliorations de l'application :

// TODO Sensor popup graph real time (ou pas popup mais autre page)
// TODO Créer des réglages pour les limites min/max des capteurs avec notifications
// TODO capture <config> (afficher dans config)