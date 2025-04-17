import 'dart:math';
import 'data_parser.dart';
import '../utils/dashboard_utils.dart';
import '../../../constants.dart';
import 'package:flutter/services.dart';
import '../components/sensors_data.dart';
import '../functions/debug_log_manager.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/functions/sensor_status_updater.dart';

void readMessage({
        required EventChannel? messageChannel,
        required Future<bool> Function(String message) sendMessage,
        required DebugLogManager debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required void Function(int) setTemp,
        required void Function(int) setHum,
        required void Function(int) setPres
}) {
        sendMessage(communicationMessageAndroid);
        String buffer = '';
        bool isCapturing = false;

        messageChannel?.receiveBroadcastStream().listen((event) {
                        if (event is Uint8List) {
                                final chunk = String.fromCharCodes(event);
                                buffer += chunk;

                                if (buffer.contains(communicationMessagePhoneStart)) {
                                        isCapturing = true;
                                        buffer = "";
                                }

                                if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                        isCapturing = false;

                                        final rawData = buffer
                                                .replaceAll(communicationMessagePhoneStart, "")
                                                .replaceAll(communicationMessagePhoneEnd, "")
                                                .trim();

                                        final lines = rawData.split('\n');
                                        if (lines.length >= 3) {
                                                final headers = lines[1].split(',').map((h) => h.trim()).toList();
                                                final values = lines[2].split(',').map((v) => v.trim()).toList();
                                                final maxHeaderLength = headers.fold<int>(0, (prev, h) => max(prev, h.length));

                                                if (rawData.contains("<status>")) {
                                                        final statusLog = "Status:\n" + headers.asMap().entries.map((entry) {
                                                                                final index = entry.key;
                                                                                final header = entry.value.toUpperCase();
                                                                                final paddedHeader = header.padRight(maxHeaderLength);
                                                                                final value = values[index];
                                                                                return "$paddedHeader : $value";
                                                                        }
                                                                ).join("\n");
                                                        debugLogManager.setLogChunk(1, statusLog);
                                                }

                                                if (rawData.contains("<data>")) {
                                                        final dataLog = "\nValeurs:\n" + headers.asMap().entries.map(
                                                                        (entry) {
                                                                                final index = entry.key;
                                                                                final header = entry.value.toUpperCase();
                                                                                final paddedHeader = header.padRight(maxHeaderLength);
                                                                                final raw = values[index];
                                                                                final formatted = double.tryParse(raw) != null ? "${double.parse(raw).toStringAsFixed(2)}${getUnitForHeader(header.toLowerCase())}" : raw;
                                                                                return "$paddedHeader : $formatted";
                                                                        }
                                                                ).join("\n");
                                                        debugLogManager.setLogChunk(2, dataLog);
                                                }
                                        }

                                        debugLogManager.updateLogs();

                                        if (rawData.contains("<data>")) {
                                                populateSensorData(rawData, [
                                                                getSensors(SensorType.internal),
                                                                getSensors(SensorType.modbus),
                                                                getSensors(SensorType.stevenson)
                                                        ]
                                                );
                                        }

                                        if (rawData.contains("<status>")) {
                                                updateSensorsData(rawData, getSensors, communicationMessageStatus, setTemp, setHum, setPres);
                                        }

                                        buffer = "";
                                }
                        }
                }
        );
}