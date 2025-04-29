/// Écoute le flux série et délègue chaque bloc complet de données à [processRawData].

import "data_processor.dart";
import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:rev_glacier_sma_mobile/utils/constants.dart";
import "package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart";
import "package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart";

void readMessage({
        required EventChannel? messageChannel,
        required Future<bool> Function(String) sendMessage,
        required DebugLogUpdater debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required void Function(int) setTemp,
        required void Function(int) setHum,
        required void Function(int) setPres,
        required void Function() onDataReceived,
        required ValueNotifier<double?> batteryVoltage
}) {
        // Demande initiale de données
        sendMessage(communicationMessageAndroid);

        var buffer = "";
        var isCapturing = false;

        messageChannel?.receiveBroadcastStream().listen(
                (event) {
                        if (event is Uint8List) {
                                buffer += String.fromCharCodes(event);

                                // Début de capture
                                if (buffer.contains(communicationMessagePhoneStart)) {
                                        isCapturing = true;
                                        buffer = "";
                                }

                                // Fin de capture → traitement
                                if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                        isCapturing = false;
                                        final rawData = buffer
                                                .replaceAll(communicationMessagePhoneStart, "")
                                                .replaceAll(communicationMessagePhoneEnd, "")
                                                .trim();

                                        // Délégation du traitement
                                        processRawData(
                                                rawData: rawData,
                                                debugLogManager: debugLogManager,
                                                getSensors: getSensors,
                                                setTemp: setTemp,
                                                setHum: setHum,
                                                setPres: setPres,
                                                onDataReceived: onDataReceived,
                                                batteryVoltage: batteryVoltage
                                        );

                                        // Réinitialisation du buffer
                                        buffer = "";
                                }
                        }
                }
        );
}