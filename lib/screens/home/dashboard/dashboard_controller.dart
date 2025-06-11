import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_reader.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Contrôleur pour l'initialisation, la gestion du flux série et le nettoyage du Dashboard.
/// Inclut un Stopwatch pour mesurer le temps écoulé depuis la connexion initiale.
class DashboardController {
        final FlutterSerialCommunication? plugin;
        final List<DeviceInfo> connectedDevices;
        final DebugLogUpdater debugLogManager;
        final MessageService messageService;
        final void Function(Duration elapsed) onConnectionLost;
        final void Function(String reason) onFatalReceived;
        final ValueNotifier<double?> batteryVoltage = ValueNotifier(null);
        final ValueNotifier<Map<String, double?>> ramNotifier = ValueNotifier({'ram_stack': null, 'ram_heap': null});
        final ValueNotifier<RawData?> firmwareNotifier = ValueNotifier(null);
        final ValueNotifier<int?> activeMaskNotifier = ValueNotifier(null);
        final ValueNotifier<RawData?> configNotifier = ValueNotifier(null);
        final ValueNotifier<int> iterationNotifier = ValueNotifier(0);
        late final ValueNotifier<bool> isInitialLoading;
        late final Stopwatch connectionStopwatch;
        Timer? pingTimer;
        EventChannel? messageChannel;

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
                connectionStopwatch = Stopwatch()..start();

                // Prépare la liaison série
                messageChannel = plugin?.getSerialMessageListener();
                plugin?.setDTR(true);

                // Lance la lecture du port série
                readMessage(
                        messageChannel: messageChannel,
                        sendAndroidMessage: messageService.sendString,
                        debugLogManager: debugLogManager,
                        getSensors: getSensors,
                        onDataReceived: () {
                                final hasData = [
                                        ...getSensors(SensorType.internal),
                                        ...getSensors(SensorType.modbus)
                                ].any((sensor) => sensor.powerStatus != null);
                                if (hasData) isInitialLoading.value = false;
                                onDataReceived();
                        },
                        batteryVoltage: batteryVoltage,
                        onIdReceived: (id) => firmwareNotifier.value = id,
                        onActiveReceived: (mask) => activeMaskNotifier.value = mask,
                        onFatalReceived: (reason) => onFatalReceived(reason),
                        onConfigReceived: (config) {configNotifier.value = config;},
                        iterationNotifier: iterationNotifier,
                        ramNotifier: ramNotifier
                );

                if (plugin != null) {
                        // Ping toutes les 2s pour détecter la perte de connexion
                        pingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
                                        final ok = await messageService.sendString(communicationMessageAndroid);
                                        if (!ok) {
                                                pingTimer?.cancel();
                                                connectionStopwatch.stop();
                                                onConnectionLost(connectionStopwatch.elapsed);
                                        }
                                }
                        );
                }

                // Demander info ACTIVE des sensors lors de la connexion
                messageService.sendString("<info>");
        }

        void dispose() {
                pingTimer?.cancel();
                isInitialLoading.dispose();
                batteryVoltage.dispose();
                firmwareNotifier.dispose();
                activeMaskNotifier.dispose();
                configNotifier.dispose();
                ramNotifier.dispose();
        }
}