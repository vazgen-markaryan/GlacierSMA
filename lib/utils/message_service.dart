import 'dart:typed_data';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

class MessageService {
        final FlutterSerialCommunication? plugin;
        final DebugLogUpdater debugLogManager;
        final bool isEmulator;
        final String heartbeatPrefix;

        MessageService({
                required this.plugin,
                required this.debugLogManager,
                this.isEmulator = false,
                this.heartbeatPrefix = '<android>'
        });

        /// Envoie un simple message de type "heartbeat" ou toute autre chaîne.
        Future<bool> sendHeartbeat(String message) async {
                if (isEmulator) return false;
                final data = Uint8List.fromList(message.codeUnits);
                try {
                        final ok = await plugin!.write(data);
                        debugLogManager.setLogChunk(0, 'Message envoyé : $message');
                        debugLogManager.updateLogs();
                        return ok;
                }
                catch (e) {
                        debugLogManager.setLogChunk(0, 'Erreur envoi : $e');
                        debugLogManager.updateLogs();
                        return false;
                }
        }

        /// Envoie un payload de 2 octets construit à partir d'un bitmask sur 16 capteurs.
        /// [enabledSensors] est une liste de 16 booléens, index 0→bit0, …, index15→bit15.
        Future<bool> sendSensorConfig(List<bool> enabledSensors, {String prefix = '<active>'}) async {
                // 1) Génère le mask 16 bits
                int mask = 0;
                for (int i = 0; i < enabledSensors.length && i < 16; i++) {
                        if (enabledSensors[i]) mask |= (1 << i);
                }
                // 2) Découpe en 2 octets (MSB puis LSB)
                final high = (mask >> 8) & 0xFF;
                final low = mask & 0xFF;
                final payload = Uint8List.fromList([high, low]);

                if (isEmulator) return false;

                final data = Uint8List.fromList([...prefix.codeUnits, ...payload]);
                try {
                        final ok = await plugin!.write(data);
                        final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
                        debugLogManager.setLogChunk(0, 'Config envoyé : $hex');
                        debugLogManager.updateLogs();
                        return ok;
                }
                catch (e) {
                        debugLogManager.setLogChunk(0, 'Erreur config : $e');
                        debugLogManager.updateLogs();
                        return false;
                }
        }

        /// Envoie un nouveau nom de station (déjà paddé à 20 bytes) au firmware.
        /// Le protocole Arduino doit reconnaître le préfixe `<name>` .
        Future<bool> sendStationName(String paddedName) async {
                // Préfixe et retour à la ligne
                const prefix = '<name>';
                final full = '$prefix$paddedName';
                try {
                        final data = Uint8List.fromList(full.codeUnits);
                        return await plugin?.write(data) ?? false;
                } catch (e) {
                        return false;
                }
        }
}