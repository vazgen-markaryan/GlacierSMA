import 'dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/test/test_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/test/test_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_manager.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard/dashboard_body.dart';

/// Regroupe toutes les fonctions/utilitaires de Home_Screen
mixin DashboardUtils on State<Home_Screen> {
        /// Clé pour accéder à l’état de ConfigScreen
        final configKey = GlobalKey<ConfigScreenState>();

        /// Clé pour accéder à l’état de TestScreen
        final testScreenKey = GlobalKey<TestScreenState>();

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
                        debugLogManager: debugManager
                );

                controller = DashboardController(
                        plugin: widget.plugin,
                        connectedDevices: widget.connectedDevices,
                        debugLogManager: debugManager,
                        messageService: messageService,
                        onConnectionLost: handleConnectionLost,
                        onFatalReceived: handleFatalError
                );

                controller.init(() => setState(() {
                                }
                        ));
        }

        Future<void> handleConnectionLost(Duration elapsed) async {
                if (!mounted) return;
                setState(() => isConnected = false);

                // Formate le temps écoulé
                final formatted = "${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m ${elapsed.inSeconds.remainder(60)}s";

                // Vérifier si TestScreen est en train de tourner un test
                final testState = testScreenKey.currentState;
                final testEnCours = testState?.isTestRunning == true;

                final result = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                                return WillPopScope(
                                        onWillPop: () async {
                                                doDisconnectAndNavigate();
                                                return true;
                                        },
                                        child: CustomPopup(
                                                title: tr("connection.disconnect"),
                                                content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                                Text(
                                                                        tr('connection.lost_connection', namedArgs: {'time': formatted}),
                                                                        style: const TextStyle(color: Colors.white70)
                                                                ),
                                                                if (testEnCours) ...[
                                                                        const SizedBox(height: 12),
                                                                        Text(
                                                                                tr('test.save_before_disconnect'),
                                                                                style: const TextStyle(color: Colors.white70)
                                                                        )
                                                                ]
                                                        ]
                                                ),
                                                actions: [
                                                        if (testEnCours) ...[
                                                                TextButton(
                                                                        onPressed: () {
                                                                                Navigator.of(context).pop(true);
                                                                                saveLogsThenDisconnect(testState!);
                                                                        },
                                                                        child: Text(tr('yes'))
                                                                ),
                                                                TextButton(
                                                                        onPressed: () {
                                                                                Navigator.of(context).pop(false);
                                                                                doDisconnectAndNavigate();
                                                                        },
                                                                        child: Text(tr('no'))
                                                                )
                                                        ] else ...[
                                                                TextButton(
                                                                        onPressed: () {
                                                                                Navigator.of(context).pop(false);
                                                                                doDisconnectAndNavigate();
                                                                        },
                                                                        child: const Text('OK', style: TextStyle(color: primaryColor))
                                                                )
                                                        ]
                                                ]
                                        )
                                );
                        }
                );

                // Si la popup est fermée autrement (ex: bouton X), on déconnecte aussi
                if (result == null) {
                        doDisconnectAndNavigate();
                }
        }

        /// Sauvegarde les logs puis déconnecte (seulement après que l’utilisateur ait fermé la popup)
        Future<void> saveLogsThenDisconnect(TestScreenState testState) async {
                final anomalies = testState.currentAnomalyLog;
                try {
                        // Cet await n’appellera doDisconnectAndNavigate() qu’après la fermeture de la popup de succès/erreur
                        await saveCsvToDownloads(context, anomalies);
                }
                catch (_) {
                        // Si l’utilisateur a annulé la sauvegarde, on disconnecte quand même
                        doDisconnectAndNavigate();
                }

                // Si la sauvegarde a réussi, on déconnecte et revient à l’écran de connexion
                doDisconnectAndNavigate();
        }

        /// Déconnecte et revient à l’écran de connexion
        void doDisconnectAndNavigate() async {
                await widget.plugin?.disconnect();
                Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ConnectionScreen())
                );
        }

        /// Mapping des raisons fatales en message utilisateur
        static const fatalMessages = {
                'GENERIC': 'home.dashboard.fatal_generic',
                'DC_FLAG_NOT_FOUND': 'home.dashboard.fatal_dcflag',
                'HARDFAULT': 'home.dashboard.fatal_hardfault',
                'WATCHDOG': 'home.dashboard.fatal_watchdog'
        };

        /// Callback quand on reçoit `<fatal>`
        Future<void> handleFatalError(String reason) async {
                // Arrête le stopwatch
                controller.connectionStopwatch.stop();
                // Arrête le pingTimer et autres notifiers
                controller.dispose();

                // Message humain des erreurs fatales du BackEnd
                final key = fatalMessages[reason] ?? 'home.dashboard.fatal_unknown';
                final humanText = tr(key, namedArgs: {'reason': reason});

                // Durée formatée HH:MM:SS
                final elapsed = controller.connectionStopwatch.elapsed;
                final hours = elapsed.inHours.toString().padLeft(2, '0');
                final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
                final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
                final formattedDuration = '$hours:$minutes:$seconds';

                await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => CustomPopup(
                                title: tr('home.dashboard.fatal_title'),
                                content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                                Text(
                                                        humanText,
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(color: Colors.white, fontSize: 16)
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                        tr('home.dashboard.fatal_duration', namedArgs: {'duration': formattedDuration}),
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(color: Colors.white70)
                                                )
                                        ]
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () {
                                                        Navigator.of(context).pop();
                                                        widget.plugin?.disconnect();
                                                        Navigator.of(context).pop();
                                                },
                                                child: Text(tr('ok'))
                                        )
                                ]
                        )
                );
        }

        /// Gère la sélection d’un onglet
        Future<void> onNavItemTapped(int index) async {
                // Si on est actuellement sur l’onglet Test (index 3) et qu’on veut en sortir…
                if (selectedIndex == 3 && index != 3) {
                        final testState = testScreenKey.currentState;
                        if (testState != null && testState.isTesting) {
                                // Ne pas changer d’onglet, et prévenir
                                await showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => CustomPopup(
                                                title: tr("home.dashboard.test_enabled"),
                                                content: Text(tr("home.dashboard.stop_test_before_switching")),
                                                actions: [
                                                        TextButton(
                                                                onPressed: () => Navigator.of(context).pop(),
                                                                child: const Text('OK')
                                                        )
                                                ]
                                        )
                                );
                                return;
                        }
                }

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
                final raw = controller.firmwareNotifier.value;
                final initial = raw != null
                        ? (raw.asMap['name'] ?? '')
                        : (widget.connectedDevices.isNotEmpty ? widget.connectedDevices.first.productName : '');

                final textController = TextEditingController(text: initial);
                String? errorText;
                final regex = RegExp(r'^[\x00-\xFF]{0,20}$'); // ASCII 0–255, max 20 chars

                final confirmed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => StatefulBuilder(
                                builder: (context, setState) {
                                        return CustomPopup(
                                                title: tr('home.dashboard.rename_title'),
                                                content: TextField(
                                                        controller: textController,
                                                        maxLength: 20,
                                                        decoration: InputDecoration(
                                                                labelText: tr('home.dashboard.rename_label'),
                                                                errorText: errorText
                                                        ),
                                                        onChanged: (value) {
                                                                setState(
                                                                        () {
                                                                                errorText = regex.hasMatch(value) ? null : tr('home.dashboard.rename_error');
                                                                        }
                                                                );
                                                        }
                                                ),
                                                actions: [
                                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('home.dashboard.cancel_button'))),
                                                        TextButton(
                                                                onPressed: errorText == null ? () => Navigator.pop(context, true) : null,
                                                                child: Text(tr('home.dashboard.confirm_button'))
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
                        message: ok ? tr('home.dashboard.snack_rename_success') : tr('home.dashboard.snack_rename_error'),
                        iconData: ok ? Icons.check_circle : Icons.error,
                        backgroundColor: ok ? Colors.green : Colors.red,
                        textColor: Colors.white,
                        iconColor: Colors.white
                );

                if (ok) {
                        final value = controller.firmwareNotifier.value!;
                        final idx = value.headers.indexOf('name');
                        value.values[idx] = textController.text;
                        controller.firmwareNotifier.value = value;
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
                        onCancel: () => setState(() => selectedIndex = 0),
                        configNotifier: controller.configNotifier
                ),

                // Environnement contrôlé
                TestScreen(
                        key: testScreenKey,
                        activeMaskNotifier: controller.activeMaskNotifier,
                        getSensors: getSensors,
                        iterationNotifier: controller.iterationNotifier
                ),

                // Paramètres
                SettingsScreen(
                        firmwareNotifier: controller.firmwareNotifier,
                        iterationNotifier: controller.iterationNotifier
                )
        ];
}