import 'bottom_navbar.dart';
import 'package:flutter/material.dart';
import '../../utils/message_service.dart';
import '../settings/settings_screen.dart';
import '../debug_log/debug_screen.dart';
import 'dashboard/dashboard_body.dart';
import 'dashboard/dashboard_header.dart';
import '../settings/sensor_config_screen.dart';
import 'dashboard/dashboard_controller.dart';
import '../debug_log/components/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import '../connection/components/disconnection_manager.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Écran principal de l'application (accueil) qui gère l'affichage
/// Il gère aussi l’état de connexion et l'affichage de la barre de navigation inférieure.
class home_screen extends StatefulWidget {
        final FlutterSerialCommunication? plugin;
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;

        const home_screen({
                Key? key,
                required this.plugin,
                required this.isConnected,
                required this.connectedDevices
        }) : super(key: key);

        @override
        State<home_screen> createState() => home_screenState();
}

class home_screenState extends State<home_screen> {
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
                                                debugLogManager: controller.debugLogManager,
                                                getSensors: getSensors
                                        );
                                }
                        ),
                        // Page Debug
                        DebugScreen(debugLogManager: controller.debugLogManager),

                        // Page Configuration capteurs
                        SensorConfigScreen(
                                activeMaskNotifier: controller.activeMaskNotifier,
                                messageService: messageService
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
        void onItemTapped(int index) {
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
                                body: Column(
                                        children: [
                                                Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                        child: Text(
                                                                pageTitles[selectedIndex],
                                                                style: const TextStyle(
                                                                        fontSize: 18,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Colors.white
                                                                )
                                                        )
                                                ),
                                                Expanded(child: pages[selectedIndex])
                                        ]
                                ),

                                // Barre de navigation en bas
                                bottomNavigationBar: BottomNavBar(
                                        selectedIndex: selectedIndex,
                                        onItemTapped: onItemTapped
                                )
                        )
                );
        }
}