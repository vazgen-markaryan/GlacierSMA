import 'dart:math';
import 'data_feeder.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_status_updater.dart';

/// Structure contenant les headers et les valeurs d'un bloc CSV.
class RawData {
        final List<String> headers;
        final List<String> values;

        RawData(this.headers, this.values);

        /// Conversion en map clé-valeur pour accéder facilement aux colonnes.
        Map<String, String> get asMap => Map.fromIterables(
                headers.map((h) => h.toLowerCase()),
                values
        );
}

/// Parseur principal du format CSV reçu de la station météo.
class RawDataParser {
        static RawData parse(String rawData) {
                // Nettoyage général avant le split
                final cleanedRaw = rawData
                        .replaceAll('\r', '')
                        .replaceAll('\u0007', ',')
                        .replaceAll('\x00', '')
                        .replaceAll('\u0000', '');

                final lines = cleanedRaw.split('\n');
                if (lines.length < 3) return RawData([], []);

                // Lecture des headers
                final headers = lines[1]
                        .split(',')
                        .map((header) => header.trim().toLowerCase().replaceAll(RegExp(r'[\x00-\x1F]'), ''))
                        .toList();

                // Lecture des valeurs, en nettoyant les bytes parasites (nulls ou padding)
                final values = lines[2]
                        .split(',')
                        .map((value) => value.trim().replaceAll(RegExp(r'[\x00-\x1F]'), ''))
                        .toList();

                return RawData(headers, values);
        }
}

/// Traitement général d’un bloc complet reçu
void processRawData({
        required String rawData,
        required DebugLogUpdater debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required ValueNotifier<double?> batteryVoltage,
        required ValueNotifier<int> iterationNotifier,
        required ValueNotifier<Map<String, double?>> ramNotifier,
        required void Function() onDataReceived,
        required void Function(RawData idData) onIdReceived,
        required void Function(int mask) onActiveReceived,
        required void Function(String reason) onFatalReceived,
        required void Function(RawData configData) onConfigReceived
}) {
        /// Bloc ID
        if (rawData.startsWith('<id>')) {
                final idData = RawDataParser.parse(rawData);
                onIdReceived(idData);

                final remaining = rawData.split('\n').skip(3).join('\n');
                if (remaining.trim().isNotEmpty) {
                        processRawData(
                                rawData: remaining,
                                debugLogManager: debugLogManager,
                                getSensors: getSensors,
                                onDataReceived: onDataReceived,
                                batteryVoltage: batteryVoltage,
                                onIdReceived: (_) {
                                },
                                onActiveReceived: onActiveReceived,
                                onFatalReceived: onFatalReceived,
                                onConfigReceived: onConfigReceived,
                                iterationNotifier: iterationNotifier,
                                ramNotifier: ramNotifier
                        );
                }
                return;
        }

        /// Bloc Config
        if (rawData.startsWith('<config>')) {
                final configData = RawDataParser.parse(rawData);
                onConfigReceived(configData);
                return;
        }

        /// Bloc Fatal
        if (rawData.contains('<fatal>')) {
                final lines = rawData.split('\n');
                final reason = lines.length >= 2 ? lines[1].trim() : 'GENERIC';
                onFatalReceived(reason);
                return;
        }

        /// Bloc Active
        if (rawData.contains('<active>')) {
                final lines = rawData.split('\n');
                if (lines.length >= 2) {
                        final maskString = lines[1].trim();
                        final hex = maskString.startsWith('0x') ? maskString.substring(2) : maskString;
                        final cleanedHex = hex.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '');
                        final mask = int.parse(cleanedHex, radix: 16);
                        onActiveReceived(mask);
                }
                return;
        }

        /// Bloc général CSV : Status ou Data
        final parsed = RawDataParser.parse(rawData);

        // Gestion de l'itération
        final iteration = parsed.headers.indexOf('iteration');
        if (iteration >= 0) {
                final newIteration = int.tryParse(parsed.values[iteration]) ?? 0;
                iterationNotifier.value = newIteration;
        }

        final headers = parsed.headers;
        final values = parsed.values;
        final maxHeaderLength = headers.fold<int>(0, (currentMax, header) => max(currentMax, header.length));

        /// Bloc Status (affiché dans le debug log)
        if (rawData.contains('<status>')) {
                final statusLog = 'Status:\n' +
                        headers.asMap().entries.map((entry) {
                                        final header = entry.value.toUpperCase().padRight(maxHeaderLength);
                                        final value = values[entry.key];
                                        return '$header : $value';
                                }
                        ).join('\n');
                debugLogManager.setLogChunk(1, statusLog);
        }

        /// Bloc Data (valeurs principales + batterie + RAM)
        if (rawData.contains('<data>')) {
                final batteryIndex = headers.indexWhere((h) => h == 'battery_voltage');
                if (batteryIndex != -1) {
                        final voltage = double.tryParse(values[batteryIndex]);
                        if (voltage != null) batteryVoltage.value = voltage;
                }

                // RAM
                final ramStackIndex = headers.indexWhere((h) => h == 'ram_stack');
                final ramHeapIndex = headers.indexWhere((h) => h == 'ram_heap');
                if (ramStackIndex != -1 && ramHeapIndex != -1) {
                        final ramStack = double.tryParse(values[ramStackIndex]);
                        final ramHeap = double.tryParse(values[ramHeapIndex]);
                        ramNotifier.value = {'ram_stack': ramStack, 'ram_heap': ramHeap};
                }

                final dataLog = '\nValeurs:\n' +
                        headers.asMap().entries.map((entry) {
                                        final header = entry.value.toUpperCase().padRight(maxHeaderLength);
                                        final raw = values[entry.key];
                                        final lowerHeader = entry.value.toLowerCase();
                                        final formatted = (lowerHeader != 'gps_latitude' && lowerHeader != 'gps_longitude' && double.tryParse(raw) != null)
                                                ? '${double.parse(raw).toStringAsFixed(2)}${getUnitForHeader(entry.value)}'
                                                : raw;
                                        return '$header : $formatted';
                                }
                        ).join('\n');
                debugLogManager.setLogChunk(2, dataLog);
        }

        debugLogManager.updateLogs();

        // Mise à jour des sensors
        if (rawData.contains('<data>')) {
                populateSensorData(rawData, [
                                getSensors(SensorType.internal),
                                getSensors(SensorType.modbus)
                        ]);
        }
        if (rawData.contains('<status>')) {
                updateSensorsData(rawData, getSensors, "<status>");
        }

        // Si des données existent, on notifie l'UI
        final hasData = [
                ...getSensors(SensorType.internal),
                ...getSensors(SensorType.modbus)
        ].any((sensor) => sensor.powerStatus != null);

        if (hasData) onDataReceived();
}