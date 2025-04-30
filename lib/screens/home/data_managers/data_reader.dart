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
        required void Function(int) setTemp,
        required void Function(int) setHum,
        required void Function(int) setPres,
        required void Function() onDataReceived,
        required ValueNotifier<double?> batteryVoltage,
        required void Function(RawData idData) onIdReceived,
        required void Function(int mask) onActiveReceived
}) {
        // Envoit initial
        sendAndroidMessage(communicationMessageAndroid);

        var buffer = '';
        var isCapturing = false;

        messageChannel?.receiveBroadcastStream().listen(
                (event) {
                        if (event is Uint8List) {
                                buffer += String.fromCharCodes(event);

                                // Début du bloc
                                if (buffer.contains(communicationMessagePhoneStart)) {
                                        isCapturing = true;
                                        buffer = '';
                                }

                                // Fin du bloc → traitement
                                if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                        isCapturing = false;
                                        var rawData = buffer
                                                .replaceAll(communicationMessagePhoneStart, '')
                                                .replaceAll(communicationMessagePhoneEnd, '')
                                                .trim();

                                        // 1) Extraction éventuelle du bloc <id>
                                        if (rawData.startsWith('<id>')) {
                                                final lines = rawData.split('\n');
                                                if (lines.length >= 3) {
                                                        final idHeaders = lines[1].split(',').map((h) => h.trim()).toList();
                                                        final idValues = lines[2].split(',').map((v) => v.trim()).toList();
                                                        onIdReceived(RawData(idHeaders, idValues));
                                                        // Supprime ces 3 lignes du flux avant de continuer
                                                        rawData = lines.skip(3).join('\n');
                                                }
                                        }

                                        // 2) Délégation au processeur principal
                                        processRawData(
                                                rawData: rawData,
                                                debugLogManager: debugLogManager,
                                                getSensors: getSensors,
                                                setTemp: setTemp,
                                                setHum: setHum,
                                                setPres: setPres,
                                                onDataReceived: onDataReceived,
                                                batteryVoltage: batteryVoltage,
                                                onActiveReceived: onActiveReceived
                                        );

                                        buffer = '';
                                }
                        }
                }
        );
}