import 'bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'dashboard/dashboard_body.dart';
import 'dashboard/dashboard_header.dart';
import 'dashboard/dashboard_controller.dart';
import '../debug_log/components/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import '../connection/components/disconnection_manager.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Écran principal de l'application (accueil) qui gère l'affichage
/// Il gère aussi l’état de connexion et l'affichage de la barre de navigation inférieure.
class Home_Screen extends StatefulWidget {
        final FlutterSerialCommunication? plugin;
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;

        const Home_Screen({
                Key? key,
                required this.plugin,
                required this.isConnected,
                required this.connectedDevices
        }) : super(key: key);

        @override
        State<Home_Screen> createState() => Home_ScreenState();
}

class Home_ScreenState extends State<Home_Screen> {
        final GlobalKey<ConfigScreenState> configKey = GlobalKey<ConfigScreenState>();
        late final DashboardController controller;
        late final MessageService messageService;
        late bool isConnected;

        // Onglet actuellement sélectionné
        int selectedIndex = 0;

        // Pages affichées selon le BottomNavigationBar
        late final List<Widget> pages;

        // Titres affichés au-dessus de chaque section
        final List<String> pageTitles = [
                'Tableau de bord',
                'Debug Logs',
                'Configuration',
                'Paramètres'
        ];

        @override
        void initState() {
                super.initState();

                final debugManager = DebugLogUpdater();

                // Initialise le service de messages
                messageService = MessageService(
                        plugin: widget.plugin,
                        debugLogManager: debugManager,
                        isEmulator: false
                );

                isConnected = widget.isConnected;

                // Initialise le contrôleur principal du Dashboard
                controller = DashboardController(
                        plugin: widget.plugin,
                        connectedDevices: widget.connectedDevices,
                        debugLogManager: debugManager,
                        messageService: messageService,
                        onConnectionLost: handleConnectionLost
                );

                controller.init(() => setState(() {
                                }
                        ));

                // Définition des pages par onglet
                pages = [
                        // Page Accueil
                        ValueListenableBuilder<bool>(
                                valueListenable: controller.isInitialLoading,
                                builder: (ctx, loading, _) {
                                        if (loading) return const Center(child: CircularProgressIndicator());
                                        return DashboardBody(
                                                getSensors: getSensors,
                                                activeMaskNotifier: controller.activeMaskNotifier
                                        );
                                }
                        ),

                        // Page Debug
                        DebugScreen(
                                debugLogManager: controller.debugLogManager,
                                activeMaskNotifier: controller.activeMaskNotifier
                        ),

                        // Page Configuration capteurs
                        ConfigScreen(
                                key: configKey,
                                activeMaskNotifier: controller.activeMaskNotifier,
                                messageService: messageService,
                                onCancel: () {
                                        // Redirige vers l’onglet “Tableau de bord” (index 0)
                                        setState(() => selectedIndex = 0);
                                }
                        ),

                        // Page Paramètres
                        SettingsScreen(firmwareNotifier: controller.firmwareNotifier)
                ];
        }

        // Appelé si la connexion est perdue
        Future<void> handleConnectionLost(Duration elapsed) async {
                if (!mounted) return;
                setState(() => isConnected = false);
                await showLostConnectionPopup(
                        context: context,
                        plugin: widget.plugin,
                        elapsedTime: elapsed
                );
        }

        // Quand un onglet est sélectionné
        Future<void> onItemTapped(int index) async {
                // Si on quitte la page Config (index 2) et qu’il y a des modifs non sauvegardées
                if (selectedIndex == 2 && index != 2) {
                        final state = configKey.currentState;
                        if (state != null &&
                                state.localMaskNotifier.value != state.initialMask) {
                                final leave = await showDialog<bool>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (ctx) => CustomPopup(
                                                title: 'Modifications non sauvegardées',
                                                content: const Text(
                                                        'Vous avez des modifications non appliquées. Quitter quand même ?'
                                                ),
                                                actions: [
                                                        TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                                child: const Text('Non')
                                                        ),
                                                        TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                                child: const Text('Oui')
                                                        )
                                                ]
                                        )
                                );
                                if (leave != true) {
                                        // On annule le changement d’onglet
                                        return;
                                }
                        }
                }
                // Si tout est ok, on change vraiment l’onglet
                setState(() => selectedIndex = index);
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return PopScope(
                        canPop: false,
                        onPopInvoked: (didPop) async {
                                if (!didPop) {
                                        final leave = await showDisconnectPopup(
                                                context: context,
                                                plugin: widget.plugin,
                                                requireConfirmation: true
                                        );
                                        if (leave) Navigator.of(context).pop();
                                }
                        },
                        child: Scaffold(
                                backgroundColor: backgroundColor,

                                // AppBar commune à toutes les pages avec statut connexion + bouton déconnexion
                                appBar: AppBar(
                                        automaticallyImplyLeading: false,
                                        backgroundColor: secondaryColor,
                                        title: DashboardHeader(
                                                isConnected: isConnected,
                                                connectedDevices: widget.connectedDevices,
                                                batteryVoltageNotifier: controller.batteryVoltage
                                        ),
                                        actions: [
                                                IconButton(
                                                        icon: const Icon(Icons.logout),
                                                        tooltip: 'Déconnexion',
                                                        onPressed: () => showDisconnectPopup(
                                                                context: context,
                                                                plugin: widget.plugin,
                                                                requireConfirmation: true
                                                        )
                                                )
                                        ]
                                ),

                                // Corps de la page avec titre dynamique + contenu de la page
                                body: pages[selectedIndex],

                                // Barre de navigation en bas
                                bottomNavigationBar: BottomNavBar(
                                        selectedIndex: selectedIndex,
                                        onItemTapped: onItemTapped
                                )
                        )
                );
        }
}