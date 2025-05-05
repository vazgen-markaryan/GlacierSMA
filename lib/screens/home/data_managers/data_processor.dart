import 'dart:math';
import 'data_feeder.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_status_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

/// Résultat du parsing CSV : listes d’en-têtes et de valeurs.
class RawData {
        final List<String> headers;
        final List<String> values;
        RawData(this.headers, this.values);
}

/// Utility pour parser le CSV d’un bloc de données brut.
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

/// Traite un bloc `rawData`, et **gère** maintenant aussi `<id>` :
void processRawData({
        required String rawData,
        required DebugLogUpdater debugLogManager,
        required List<SensorsData> Function(SensorType) getSensors,
        required void Function() onDataReceived,
        required ValueNotifier<double?> batteryVoltage,
        required void Function(RawData idData) onIdReceived,
        required void Function(int mask) onActiveReceived
}) {
        // --- 1) Nouveau : bloc <id> ---
        if (rawData.startsWith('<id>')) {
                // On utilise exactement le même parser CSV
                final idData = RawDataParser.parse(rawData);
                onIdReceived(idData);

                // Puis on retire ces 3 lignes avant de continuer
                final remaining = rawData.split('\n').skip(3).join('\n');
                // On ré-appelle processRawData sur le reste (status/data)
                if (remaining.trim().isNotEmpty) {
                        processRawData(
                                rawData: remaining,
                                debugLogManager: debugLogManager,
                                getSensors: getSensors,
                                onDataReceived: onDataReceived,
                                batteryVoltage: batteryVoltage,
                                onIdReceived: (_) {
                                },
                                onActiveReceived: onActiveReceived
                        );
                }
                return;
        }

        // --- 2) Bloc <active> ---
        if (rawData.contains('<active>')) {
                final lines = rawData.split('\n');
                if (lines.length >= 2) {
                        final maskStr = lines[1].trim();
                        try {
                                final hex = maskStr.startsWith('0x') ? maskStr.substring(2) : maskStr;
                                final mask = int.parse(hex, radix: 16);
                                onActiveReceived(mask);
                        }
                        catch (_) {
                        }
                }
                return;
        }

        // --- 3) Parsing CSV standard (status / data) ---
        final parsed = RawDataParser.parse(rawData);
        final headers = parsed.headers;
        final values = parsed.values;
        final maxHeaderLength = headers.fold<int>(0, (p, h) => max(p, h.length));

        // STATUS
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

        // DATA + Batterie
        if (rawData.contains('<data>')) {
                final batIdx = headers.indexWhere((h) => h.toLowerCase() == 'battery_voltage');
                if (batIdx != -1) {
                        final v = double.tryParse(values[batIdx]);
                        if (v != null) batteryVoltage.value = v;
                }
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

        debugLogManager.updateLogs();

        // Mise à jour capteurs
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

        // Notification UI si au moins un capteur est actif
        final hasData = [
                ...getSensors(SensorType.internal),
                ...getSensors(SensorType.modbus)
        ].any((s) => s.powerStatus != null);
        if (hasData) onDataReceived();
}