/// Écoute le flux série et délègue chaque bloc complet de données à [processRawData].

import "data_processor.dart";
import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:rev_glacier_sma_mobile/utils/constants.dart";
import "package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart";
import "package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart";

void readMessage({
        required EventChannel? messageChannel,
        required Future<bool> Function(String) sendAndroidMessage,
        required DebugLogUpdater debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required void Function() onDataReceived,
        required ValueNotifier<double?> batteryVoltage,
        required void Function(RawData idData) onIdReceived,
        required void Function(int mask) onActiveReceived
}) {
        // Envoi initial
        sendAndroidMessage(communicationMessageAndroid);

        var buffer = '';
        var isCapturing = false;

        messageChannel?.receiveBroadcastStream().listen((event) {
                        if (event is Uint8List) {
                                buffer += String.fromCharCodes(event);

                                // Début du bloc
                                if (buffer.contains(communicationMessagePhoneStart)) {
                                        isCapturing = true;
                                        buffer = '';
                                }

                                // Fin du bloc → délégation
                                if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                        isCapturing = false;
                                        final rawData = buffer
                                                .replaceAll(communicationMessagePhoneStart, '')
                                                .replaceAll(communicationMessagePhoneEnd, '')
                                                .trim();

                                        // On passe tout à processRawData, qui gère l’ID + le reste
                                        processRawData(
                                                rawData: rawData,
                                                debugLogManager: debugLogManager,
                                                getSensors: getSensors,
                                                onDataReceived: onDataReceived,
                                                batteryVoltage: batteryVoltage,
                                                onIdReceived: onIdReceived,
                                                onActiveReceived: onActiveReceived
                                        );

                                        buffer = '';
                                }
                        }
                }
        );
}