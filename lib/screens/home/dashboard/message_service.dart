/// Service pour envoyer des messages via le plugin série et journaliser.

import 'dart:typed_data';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

class MessageService {
        final FlutterSerialCommunication? plugin;
        final DebugLogUpdater debugLogManager;
        final bool isEmulator;

        MessageService({
                required this.plugin,
                required this.debugLogManager,
                required this.isEmulator
        });

        // Envoie une chaîne simple
        Future<bool> sendMessage(String message) async {
                if (isEmulator) return false;
                final data = Uint8List.fromList(message.codeUnits);
                try {
                        final ok = await plugin!.write(data);
                        debugLogManager.setLogChunk(0, "Message envoyé : $message");
                        debugLogManager.updateLogs();
                        return ok;
                }
                catch (e) {
                        debugLogManager.setLogChunk(0, "Erreur envoi : $e");
                        debugLogManager.updateLogs();
                        return false;
                }
        }

        // Envoie un message custom (prefix + payload).
        Future<bool> sendCustomMessage(String prefix, Uint8List payload) async {
                if (isEmulator) return false;
                final data = Uint8List.fromList([...prefix.codeUnits, ...payload]);
                try {
                        final ok = await plugin!.write(data);
                        final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
                        debugLogManager.setLogChunk(0, "Message envoyé : $hex");
                        debugLogManager.updateLogs();
                        return ok;
                }
                catch (e) {
                        debugLogManager.setLogChunk(0, "Erreur envoi custom : $e");
                        debugLogManager.updateLogs();
                        return false;
                }
        }
}