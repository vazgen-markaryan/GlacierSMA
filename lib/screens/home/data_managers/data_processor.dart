import 'dart:math';
import 'data_feeder.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_status_updater.dart';

/// Résultat du parsing CSV : listes d’en-têtes et de valeurs.
/// Et accès par clé via [asMap].
class RawData {
        final List<String> headers;
        final List<String> values;

        RawData(this.headers, this.values);

        /// Accès aux valeurs par nom de colonne (en minuscules).
        Map<String, String> get asMap => Map.fromIterables(headers.map((headers) => headers.toLowerCase()), values);
}

/// Utility pour parser le CSV d’un bloc de données brut.
class RawDataParser {
        /// Prend rawData (>=3 lignes) et renvoie [RawData] propre.
        static RawData parse(String rawData) {
                final lines = rawData.split('\n');
                if (lines.length < 3) return RawData([], []);

                final headers = lines[1]
                        .split(',')
                        .map((h) => h.trim().toLowerCase())
                        .toList();

                final values = lines[2]
                        .split(',')
                        .map((v) => v.trim().replaceAll('\u0007', ','))
                        .toList();

                return RawData(headers, values);
        }
}

/// Traite un bloc `rawData`, gère `<id>`, `<fatal>` et `<active>`.
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
        // Bloc <id>
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

        // Bloc <config>
        if (rawData.startsWith('<config>')) {
                final configData = RawDataParser.parse(rawData);
                onConfigReceived(configData);
                return;
        }

        // Bloc <fatal>
        if (rawData.contains('<fatal>')) {
                final lines = rawData.split('\n');
                final reason = lines.length >= 2 ? lines[1].trim() : 'GENERIC';
                onFatalReceived(reason);
                return;
        }

        // Bloc <active>
        if (rawData.contains('<active>')) {
                final lines = rawData.split('\n');
                if (lines.length >= 2) {
                        final maskString = lines[1].trim();
                        try {
                                final hex = maskString.startsWith('0x')
                                        ? maskString.substring(2)
                                        : maskString;
                                final mask = int.parse(hex, radix: 16);
                                onActiveReceived(mask);
                        }
                        catch (_) {
                        }
                }
                return;
        }

        // Parsing CSV standard (status / data)
        final parsed = RawDataParser.parse(rawData);

        // Récupère et notifie la nouvelle itération
        final idxIter = parsed.headers.indexOf('iteration');
        if (idxIter >= 0) {
                final newIt = int.tryParse(parsed.values[idxIter]) ?? 0;
                iterationNotifier.value = newIt;
        }

        final headers = parsed.headers;
        final values = parsed.values;
        final maxHeaderLength = headers.fold<int>(0, (p, h) => max(p, h.length));

        // Status
        if (rawData.contains('<status>')) {
                final statusLog = 'Status:\n' +
                        headers.asMap().entries.map((e) {
                                        final header = e.value.toUpperCase().padRight(maxHeaderLength);
                                        final value = values[e.key];
                                        return '$header : $value';
                                }
                        ).join('\n');
                debugLogManager.setLogChunk(1, statusLog);
        }

        // Data + Batterie + RAM
        if (rawData.contains('<data>')) {
                final batteryIndex = headers.indexWhere((h) => h.toLowerCase() == 'battery_voltage');
                if (batteryIndex != -1) {
                        final voltage = double.tryParse(values[batteryIndex]);
                        if (voltage != null) batteryVoltage.value = voltage;
                }

                // RAM
                final ramStackIndex = headers.indexWhere((h) => h.toLowerCase() == 'ram_stack');
                final ramHeapIndex = headers.indexWhere((h) => h.toLowerCase() == 'ram_heap');
                if (ramStackIndex != -1 && ramHeapIndex != -1) {
                        final ramStack = double.tryParse(values[ramStackIndex]);
                        final ramHeap = double.tryParse(values[ramHeapIndex]);
                        ramNotifier.value = {'ram_stack': ramStack, 'ram_heap': ramHeap};
                }

                final dataLog = '\nValeurs:\n' +
                        headers.asMap().entries.map((e) {
                                        final header = e.value.toUpperCase().padRight(maxHeaderLength);
                                        final raw = values[e.key];
                                        final formatted = double.tryParse(raw) != null
                                                ? '${double.parse(raw).toStringAsFixed(2)}'
                                                '${getUnitForHeader(e.value.toLowerCase())}'
                                                : raw;
                                        return '$header : $formatted';
                                }
                        ).join('\n');
                debugLogManager.setLogChunk(2, dataLog);
        }

        debugLogManager.updateLogs();

        // Mise à jour des capteurs
        if (rawData.contains('<data>')) {
                populateSensorData(
                        rawData,
                        [getSensors(SensorType.internal), getSensors(SensorType.modbus)]
                );
        }
        if (rawData.contains('<status>')) {
                updateSensorsData(
                        rawData,
                        getSensors,
                        communicationMessageStatus
                );
        }

        // Notification UI
        final hasData = [
                ...getSensors(SensorType.internal),
                ...getSensors(SensorType.modbus)
        ].any((s) => s.powerStatus != null);
        if (hasData) onDataReceived();
}