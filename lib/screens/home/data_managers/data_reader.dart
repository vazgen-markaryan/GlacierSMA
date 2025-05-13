import 'data_processor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

/// Écoute le flux série et délègue chaque bloc complet à [processRawData].
void readMessage({
        required EventChannel? messageChannel,
        required Future<bool> Function(String) sendAndroidMessage,
        required DebugLogUpdater debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required void Function() onDataReceived,
        required ValueNotifier<double?> batteryVoltage,
        required void Function(RawData idData) onIdReceived,
        required void Function(int mask) onActiveReceived,
        required void Function(String reason) onFatalReceived,
        required void Function(RawData configData) onConfigReceived
}) {
        sendAndroidMessage(communicationMessageAndroid);

        var buffer = '';
        var isCapturing = false;

        messageChannel?.receiveBroadcastStream().listen(
                (event) {
                        if (event is Uint8List) {
                                buffer += String.fromCharCodes(event);

                                if (buffer.contains(communicationMessagePhoneStart)) {
                                        isCapturing = true;
                                        buffer = '';
                                }

                                if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                        isCapturing = false;
                                        final rawData = buffer
                                                .replaceAll(communicationMessagePhoneStart, '')
                                                .replaceAll(communicationMessagePhoneEnd, '')
                                                .trim();

                                        processRawData(
                                                rawData: rawData,
                                                debugLogManager: debugLogManager,
                                                getSensors: getSensors,
                                                onDataReceived: onDataReceived,
                                                batteryVoltage: batteryVoltage,
                                                onIdReceived: onIdReceived,
                                                onActiveReceived: onActiveReceived,
                                                onFatalReceived: onFatalReceived,
                                                onConfigReceived: onConfigReceived
                                        );

                                        buffer = '';
                                }
                        }
                }
        );
}