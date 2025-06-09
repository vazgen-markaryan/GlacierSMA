import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_log_updater.dart';

class MessageService {
        final FlutterSerialCommunication? plugin;
        final DebugLogUpdater debugLogManager;

        MessageService({
                required this.plugin,
                required this.debugLogManager,
        });

        /// Envoie un simple message de type "heartbeat" ou toute autre chaîne.
        Future<bool> sendString(String message) async {
                try {
                        final ok = await plugin!.write(Uint8List.fromList(message.codeUnits));
                        final sentLog = tr('debug.message_sent', namedArgs: {'log': message});
                        debugLogManager.setLogChunk(0, sentLog);
                        debugLogManager.updateLogs();
                        return ok;
                }
                catch (error) {
                        final errorLog = tr('debug.message_error', namedArgs: {'log': error.toString()});
                        debugLogManager.setLogChunk(0, errorLog);
                        debugLogManager.updateLogs();
                        return false;
                }
        }

        /// Envoie un payload de 2 octets construit à partir d'un bitmask sur 16 capteurs.
        /// [enabledSensors] est une liste de 16 booléens, index 0→bit0, …, index15→bit15.
        Future<bool> sendSensorConfig(List<bool> enabledSensors, {String prefix = '<active>'}) async {
                // Génère le mask 16 bits
                int mask = 0;
                for (int i = 0; i < enabledSensors.length && i < 16; i++) {
                        if (enabledSensors[i]) mask |= (1 << i);
                }

                // Découpe en 2 octets (MSB puis LSB)
                final high = (mask >> 8) & 0xFF;
                final low = mask & 0xFF;
                final payload = Uint8List.fromList([high, low]);
                final data = Uint8List.fromList([...prefix.codeUnits, ...payload]);

                try {
                        return await plugin!.write(data);
                }
                catch (error) {
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
                }
                catch (error) {
                        return false;
                }
        }

        /// Envoie une nouvelle valeur de configuration au firmware.
        Future<bool> sendConfigDouble(String typeChar, double value) async {
                final prefix = '<cfg>';
                final byteData = ByteData(4)..setFloat32(0, value, Endian.little);
                final payload = Uint8List.fromList([typeChar.codeUnitAt(0), ...byteData.buffer.asUint8List()]);
                final data = Uint8List.fromList([...prefix.codeUnits, ...payload]);
                return plugin!.write(data);
        }

        /// Envoie une nouvelle valeur de configuration au firmware.
        Future<bool> sendConfigInteger(String typeChar, int value) async {
                final prefix = '<cfg>';
                final byteData = ByteData(4)..setUint32(0, value, Endian.little);
                final payload = Uint8List.fromList([typeChar.codeUnitAt(0), ...byteData.buffer.asUint8List()]);
                final data = Uint8List.fromList([...prefix.codeUnits, ...payload]);
                return plugin!.write(data);
        }
}