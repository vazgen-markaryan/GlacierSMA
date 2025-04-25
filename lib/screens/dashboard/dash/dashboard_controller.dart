/// Contrôleur pour l'initialisation, la gestion du flux série et le nettoyage du Dashboard.
/// Inclut un Stopwatch pour mesurer le temps écoulé depuis la connexion initiale.

import 'dart:async';
import '../utils/constants.dart';
import 'message_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../sensors/sensors_data.dart';
import '../debug/debug_log_manager.dart';
import '../data_managers/data_capture.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

class DashboardController {
        final FlutterSerialCommunication? plugin;
        final List<DeviceInfo> connectedDevices;
        final DebugLogManager debugLogManager;
        final MessageService messageService;

        // Callback pour notifier la perte de connexion, avec la durée écoulée.
        final void Function(Duration elapsed) onConnectionLost;

        late final ValueNotifier<bool> isInitialLoading;
        final ValueNotifier<double?> batteryVoltage = ValueNotifier(null);

        Timer? pingTimer;
        EventChannel? messageChannel;
        bool isEmulator = false;

        // Stevenson statuses
        int stevensonTemp = 0, stevensonHum = 0, stevensonPress = 0;

        // Pour mesurer le temps depuis la connexion
        late final Stopwatch connectionStopwatch;

        DashboardController({
                required this.plugin,
                required this.connectedDevices,
                required this.debugLogManager,
                required this.messageService,
                required this.onConnectionLost
        }) {
                isInitialLoading = ValueNotifier(true);
        }

        // Initialise la connexion série et démarre la capture.
        Future<void> init(void Function() onDataReceived) async {
                final info = await DeviceInfoPlugin().androidInfo;
                isEmulator = !info.isPhysicalDevice;

                if (isEmulator) {
                        // UI-only : simuler un délai de chargement
                        await Future.delayed(const Duration(seconds: 1));
                        isInitialLoading.value = false;
                        return;
                }

                // Appareil réel : démarrer le stopwatch avant la communication
                connectionStopwatch = Stopwatch()..start();

                // Setup du canal série
                messageChannel = plugin?.getSerialMessageListener();
                plugin?.setDTR(true);

                // Démarrer la lecture
                readMessage(
                        messageChannel: messageChannel,
                        sendMessage: messageService.sendMessage,
                        debugLogManager: debugLogManager,
                        getSensors: getSensors,
                        setTemp: (v) => stevensonTemp = v,
                        setHum: (v) => stevensonHum = v,
                        setPres: (v) => stevensonPress = v,
                        onDataReceived: () {
                                final hasData = [
                                        ...getSensors(SensorType.internal),
                                        ...getSensors(SensorType.modbus),
                                        ...getSensors(SensorType.stevenson),
                                        ...getSensors(SensorType.stevensonStatus)
                                ].any((s) => s.powerStatus != null);
                                if (hasData) isInitialLoading.value = false;
                                onDataReceived();
                        },
                        batteryVoltage: batteryVoltage
                );

                // Ping toutes les 2s pour vérifier la connexion
                pingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
                                final ok = await messageService.sendMessage(communicationMessageAndroid);
                                if (!ok) {
                                        pingTimer?.cancel();
                                        connectionStopwatch.stop();
                                        onConnectionLost(connectionStopwatch.elapsed);
                                }
                        }
                );
        }

        void dispose() {
                pingTimer?.cancel();
                isInitialLoading.dispose();
                batteryVoltage.dispose();
        }
}