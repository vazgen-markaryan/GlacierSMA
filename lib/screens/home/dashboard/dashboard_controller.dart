/// Contrôleur pour l'initialisation, la gestion du flux série et le nettoyage du Dashboard.
/// Inclut un Stopwatch pour mesurer le temps écoulé depuis la connexion initiale.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_reader.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

class DashboardController {
        final FlutterSerialCommunication? plugin;
        final List<DeviceInfo> connectedDevices;
        final DebugLogUpdater debugLogManager;
        final MessageService messageService;
        final void Function(Duration elapsed) onConnectionLost;
        final void Function(String reason) onFatalReceived;
        late final ValueNotifier<bool> isInitialLoading;
        final ValueNotifier<double?> batteryVoltage = ValueNotifier(null);
        final ValueNotifier<RawData?> firmwareNotifier = ValueNotifier(null);
        final ValueNotifier<int?> activeMaskNotifier = ValueNotifier(null);
        final ValueNotifier<RawData?> configNotifier = ValueNotifier(null);
        Timer? pingTimer;
        EventChannel? messageChannel;
        bool isEmulator = false;
        late final Stopwatch connectionStopwatch;

        DashboardController({
                required this.plugin,
                required this.connectedDevices,
                required this.debugLogManager,
                required this.messageService,
                required this.onConnectionLost,
                required this.onFatalReceived
        }) {
                isInitialLoading = ValueNotifier(true);
        }

        Future<void> init(void Function() onDataReceived) async {
                final info = await DeviceInfoPlugin().androidInfo;
                isEmulator = !info.isPhysicalDevice;

                if (isEmulator) {
                        // Simule un chargement rapide en émulateur
                        await Future.delayed(const Duration(seconds: 1));
                        isInitialLoading.value = false;
                        return;
                }

                // Vrai matériel : démarrage du stopwatch
                connectionStopwatch = Stopwatch()..start();

                // Prépare la liaison série
                messageChannel = plugin?.getSerialMessageListener();
                plugin?.setDTR(true);

                // Lance la lecture du port série
                readMessage(
                        messageChannel: messageChannel,
                        sendAndroidMessage: messageService.sendHeartbeat,
                        debugLogManager: debugLogManager,
                        getSensors: getSensors,
                        onDataReceived: () {
                                final hasData = [
                                        ...getSensors(SensorType.internal),
                                        ...getSensors(SensorType.modbus)
                                ].any((s) => s.powerStatus != null);
                                if (hasData) isInitialLoading.value = false;
                                onDataReceived();
                        },
                        batteryVoltage: batteryVoltage,
                        onIdReceived: (id) => firmwareNotifier.value = id,
                        onActiveReceived: (mask) => activeMaskNotifier.value = mask,
                        onFatalReceived: (reason) => onFatalReceived(reason),
                        onConfigReceived: (config) {configNotifier.value = config;}
                );

                // Ping toutes les 2s pour détecter la perte de connexion
                pingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
                                final ok = await messageService.sendHeartbeat(communicationMessageAndroid);
                                if (!ok) {
                                        pingTimer?.cancel();
                                        connectionStopwatch.stop();
                                        onConnectionLost(connectionStopwatch.elapsed);
                                }
                        }
                );

                // Demander info ACTIVE des sensors lors de la connexion
                messageService.sendHeartbeat("<info>");
        }

        void dispose() {
                pingTimer?.cancel();
                isInitialLoading.dispose();
                batteryVoltage.dispose();
                firmwareNotifier.dispose();
                activeMaskNotifier.dispose();
                configNotifier.dispose();
        }
}