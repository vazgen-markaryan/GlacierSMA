/// Parse et traite un bloc de données brut (>=3 lignes CSV) :
///  1. Extraction des headers/values  
///  2. Mise à jour des logs de debug (STATUS / VALEURS)  
///  3. Mise à jour du voltage de batterie  
///  4. Mise à jour des capteurs (populateSensorData + updateSensorsData)  
///  5. Notification UI via onDataReceived()

import 'dart:math';
import '../utils/switch_utils.dart';
import 'data_feeder.dart';
import '../utils/constants.dart';
import '../sensors/sensors_data.dart';
import 'package:flutter/material.dart';
import '../debug/debug_log_manager.dart';
import '../sensors/sensor_status_updater.dart';

/// Résultat du parsing CSV : listes d’en-têtes et de valeurs.
class RawData {
        final List<String> headers;
        final List<String> values;
        RawData(this.headers, this.values);
}

/// Utility pour parser le CSV d’un bloc de données brutal.
class RawDataParser {
        /// Prend rawData (>=3 lignes) et renvoie [RawData] propre.
        static RawData parse(String rawData) {
                final lines = rawData.split('\n');
                if (lines.length < 3) return RawData([], []);
                final headers = lines[1].split(',').map((h) => h.trim()).toList();
                final values = lines[2].split(',').map((v) => v.trim()).toList();
                return RawData(headers, values);
        }
}

/// Traite un bloc `rawData` : logs, batterie, capteurs et callback UI.
void processRawData({
        required String rawData,
        required DebugLogManager debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required void Function(int) setTemp,
        required void Function(int) setHum,
        required void Function(int) setPres,
        required void Function() onDataReceived,
        required ValueNotifier<double?> batteryVoltage
}) {
        // 1. Parsing CSV
        final parsed = RawDataParser.parse(rawData);
        final headers = parsed.headers;
        final values = parsed.values;
        final maxHeaderLength = headers.fold<int>(0, (prev, h) => max(prev, h.length));

        // 2. Logs STATUS
        if (rawData.contains('<status>')) {
                final statusLog = 'Status:\n' +
                        headers.asMap().entries.map((e) {
                                        final hdr = e.value.toUpperCase().padRight(maxHeaderLength);
                                        final val = values[e.key];
                                        return '$hdr : $val';
                                }
                        ).join('\n');
                debugLogManager.setLogChunk(1, statusLog);
        }

        // 3. Logs DATA + batterie
        if (rawData.contains('<data>')) {
                // Batterie
                final batIdx = headers.indexWhere((h) => h.toLowerCase() == 'battery_voltage');
                if (batIdx != -1) {
                        final v = double.tryParse(values[batIdx]);
                        if (v != null) batteryVoltage.value = v;
                }
                // Data log
                final dataLog = '\nValeurs:\n' +
                        headers.asMap().entries.map((e) {
                                        final hdr = e.value.toUpperCase().padRight(maxHeaderLength);
                                        final raw = values[e.key];
                                        final formatted = double.tryParse(raw) != null
                                                ? '${double.parse(raw).toStringAsFixed(2)}${getUnitForHeader(e.value.toLowerCase())}'
                                                : raw;
                                        return '$hdr : $formatted';
                                }
                        ).join('\n');
                debugLogManager.setLogChunk(2, dataLog);
        }

        // 4. Publier les logs
        debugLogManager.updateLogs();

        // 5. Mise à jour des capteurs
        if (rawData.contains('<data>')) {
                populateSensorData(
                        rawData,
                        [
                                getSensors(SensorType.internal),
                                getSensors(SensorType.modbus),
                                getSensors(SensorType.stevenson)
                        ]
                );
        }
        if (rawData.contains('<status>')) {
                updateSensorsData(
                        rawData,
                        getSensors,
                        communicationMessageStatus,
                        setTemp,
                        setHum,
                        setPres
                );
        }

        // 6. Notification UI
        final hasData = [
                ...getSensors(SensorType.internal),
                ...getSensors(SensorType.modbus),
                ...getSensors(SensorType.stevenson),
                ...getSensors(SensorType.stevensonStatus)
        ].any((s) => s.powerStatus != null);
        if (hasData) onDataReceived();
}