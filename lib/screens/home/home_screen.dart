import 'bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import '../connection/components/disconnection_manager.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard/dashboard_body.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard/dashboard_header.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard/dashboard_controller.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

/// Écran principal qui gère l'affichage des onglets et la navigation
class Home_Screen extends StatefulWidget {
        /// Plugin de communication série
        final FlutterSerialCommunication? plugin;
        /// État initial de la connexion
        final bool isConnected;
        /// Liste des appareils connectés
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
        /// Clé pour accéder à l'état de l'écran de configuration
        final configKey = GlobalKey<ConfigScreenState>();
        /// Contrôleur du dashboard (gestion des données, notifications, etc.)
        late final DashboardController controller;
        /// Service de messagerie pour envoyer les configurations
        late final MessageService messageService;
        /// Indique si l'application est connectée
        late bool isConnected;
        /// Index de l'onglet sélectionné
        int selectedIndex = 0;

        @override
        void initState() {
                super.initState();
                // Initialisation du controller et du service de messages
                initController();
                // Conservation de l'état de connexion initial
                isConnected = widget.isConnected;
        }

        /// Initialise le DashboardController et le MessageService
        void initController() {
                final debugManager = DebugLogUpdater();
                messageService = MessageService(
                        plugin: widget.plugin,
                        debugLogManager: debugManager,
                        isEmulator: false
                );
                controller = DashboardController(
                        plugin: widget.plugin,
                        connectedDevices: widget.connectedDevices,
                        debugLogManager: debugManager,
                        messageService: messageService,
                        onConnectionLost: handleConnectionLost
                );
                // Lancement de l'initialisation (chargement des capteurs, logs, etc.)
                controller.init(() => setState(() {
                                }
                        ));
        }

        /// Gestion de la perte de connexion : affiche une popup et met à jour l'état
        Future<void> handleConnectionLost(Duration elapsed) async {
                if (!mounted) return;
                setState(() => isConnected = false);
                await showLostConnectionPopup(
                        context: context,
                        plugin: widget.plugin,
                        elapsedTime: elapsed
                );
        }

        /// Lorsque l'utilisateur clique sur un onglet de la barre de navigation
        Future<void> onNavItemTapped(int index) async {
                // Si on quitte l’onglet Config…
                if (selectedIndex == 2 && index != 2) {
                        final configState = configKey.currentState;
                        if (configState != null) {
                                // On délègue à ConfigScreenState.confirmDiscard()
                                final canLeave = await configState.confirmDiscard();
                                if (!canLeave) return;
                        }
                }
                setState(() => selectedIndex = index);
        }

        /// Gestion de la touche retour système (Android)
        Future<void> handleSystemPop(bool didPop) async {
                if (!didPop) {
                        final leave = await showDisconnectPopup(
                                context: context,
                                plugin: widget.plugin,
                                requireConfirmation: true
                        );
                        if (leave) Navigator.of(context).pop();
                }
        }

        /// Construit l'AppBar commune à toutes les pages
        PreferredSizeWidget buildAppBar() {
                return AppBar(
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
                );
        }

        /// Liste des pages correspondant à chaque onglet
        List<Widget> get pages => [
                // Onglet Dashboard
                ValueListenableBuilder<bool>(
                        valueListenable: controller.isInitialLoading,
                        builder: (_, loading, __) {
                                if (loading) {
                                        return const Center(child: CircularProgressIndicator());
                                }
                                return DashboardBody(
                                        getSensors: getSensors,
                                        activeMaskNotifier: controller.activeMaskNotifier
                                );
                        }
                ),
                // Onglet Debug Logs
                DebugScreen(
                        debugLogManager: controller.debugLogManager,
                        activeMaskNotifier: controller.activeMaskNotifier
                ),
                // Onglet Configuration
                ConfigScreen(
                        key: configKey,
                        activeMaskNotifier: controller.activeMaskNotifier,
                        messageService: messageService,
                        onCancel: () => setState(() => selectedIndex = 0)
                ),
                // Onglet Paramètres
                SettingsScreen(firmwareNotifier: controller.firmwareNotifier)
        ];

        @override
        Widget build(BuildContext context) {
                return PopScope(
                        canPop: false,
                        onPopInvoked: handleSystemPop,
                        child: Scaffold(
                                backgroundColor: backgroundColor,
                                appBar: buildAppBar(),
                                body: pages[selectedIndex],
                                bottomNavigationBar: BottomNavBar(
                                        selectedIndex: selectedIndex,
                                        onItemTapped: onNavItemTapped
                                )
                        )
                );
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }
}