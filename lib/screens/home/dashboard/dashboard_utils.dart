import 'dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard/dashboard_body.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/components/disconnection_manager.dart';

/// Regroupe toutes les fonctions/utilitaires de Home_Screen
mixin DashboardUtils on State<Home_Screen> {
        /// Clé pour accéder à l’état de ConfigScreen
        final configKey = GlobalKey<ConfigScreenState>();

        /// Contrôleurs et services partagés
        late final DashboardController controller;
        late final MessageService messageService;

        /// État de connexion et onglet courant
        late bool isConnected;
        int selectedIndex = 0;

        /// Initialise DashboardController, MessageService, etc.
        void initDashboard(Home_Screen widget) {
                isConnected = widget.isConnected;

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

                controller.init(() => setState(() {
                                }
                        ));
        }

        /// Affiche un popup si la connexion est perdue
        Future<void> handleConnectionLost(Duration elapsed) async {
                if (!mounted) return;
                setState(() => isConnected = false);
                await showLostConnectionPopup(
                        context: context,
                        plugin: widget.plugin,
                        elapsedTime: elapsed
                );
        }

        /// Gère la sélection d’un onglet
        Future<void> onNavItemTapped(int index) async {
                // Si on quitte l’onglet Config
                if (selectedIndex == 2 && index != 2) {
                        final config = configKey.currentState;
                        if (config != null && !await config.confirmDiscard()) return;
                }
                setState(() => selectedIndex = index);
        }

        /// Gère la touche retour système (Android)
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

        /// Ouvre la popup de renommage et envoie au firmware
        Future<void> showRenameDialog() async {
                // Valeur initiale depuis <id> ou productName
                final raw = controller.firmwareNotifier.value;
                final initial = raw != null
                        ? (raw.asMap['name'] ?? '')
                        : (widget.connectedDevices.isNotEmpty
                                ? widget.connectedDevices.first.productName
                                : '');

                final textController = TextEditingController(text: initial);
                String? errorText;
                final regex = RegExp(r'^[\x00-\xFF]{0,20}$'); // ASCII 0–255, max 20 chars

                final confirmed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => StatefulBuilder(builder: 
                                (context, setState) {
                                        return CustomPopup(
                                                title: 'Modifier le nom de la station',
                                                content: TextField(
                                                        controller: textController,
                                                        maxLength: 20,
                                                        decoration: InputDecoration(
                                                                labelText: 'Nom',
                                                                errorText: errorText
                                                        ),
                                                        onChanged: (v) {
                                                                setState(() {
                                                                                errorText = regex.hasMatch(v) ? null : 'Caractère non valide détecté !';
                                                                        }
                                                                );
                                                        }
                                                ),
                                                actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                                        TextButton(
                                                                onPressed: errorText == null ? () => Navigator.pop(context, true) : null,
                                                                child: const Text('Valider')
                                                        )
                                                ]
                                        );
                                }
                        )
                );
                if (confirmed != true) return;

                // Trunc à 20 bytes
                var name = textController.text;
                final bytes = name.codeUnits;
                if (bytes.length < 20) {
                        name = name + '\x00' * (20 - bytes.length);
                }
                else if (bytes.length > 20) {
                        name = String.fromCharCodes(bytes.sublist(0, 20));
                }

                final ok = await messageService.sendStationName(name);

                showCustomSnackBar(
                        context,
                        message: ok ? 'Nom de station mis à jour' : 'Erreur lors de l’envoi du nom',
                        iconData: ok ? Icons.check_circle : Icons.error,
                        backgroundColor: ok ? Colors.green : Colors.red,
                        textColor: Colors.white,
                        iconColor: Colors.white
                );
                if (ok) {
                        // Mise à jour locale pour rafraîchir l’en-tête
                        final u = controller.firmwareNotifier.value!;
                        final idx = u.headers.indexOf('name');
                        u.values[idx] = textController.text;
                        controller.firmwareNotifier.value = u;
                }
        }

        /// Les 4 pages de la BottomNavBar
        List<Widget> get pages => [
                // Tableau de bord
                ValueListenableBuilder<bool>(
                        valueListenable: controller.isInitialLoading,
                        builder: (_, loading, __) {
                                if (loading) return const Center(child: CircularProgressIndicator());
                                return DashboardBody(
                                        getSensors: getSensors,
                                        activeMaskNotifier: controller.activeMaskNotifier
                                );
                        }
                ),

                // Debug logs
                DebugScreen(
                        debugLogManager: controller.debugLogManager,
                        activeMaskNotifier: controller.activeMaskNotifier
                ),

                // Configuration capteurs
                ConfigScreen(
                        key: configKey,
                        activeMaskNotifier: controller.activeMaskNotifier,
                        messageService: messageService,
                        onCancel: () => setState(() => selectedIndex = 0)
                ),

                // Paramètres
                SettingsScreen(firmwareNotifier: controller.firmwareNotifier)
        ];
}