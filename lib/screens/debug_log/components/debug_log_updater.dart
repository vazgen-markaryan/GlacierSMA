/// Gère le tampon temporaire de logs et publie la liste formatée (avec les sections “STATUS” et “VALEURS”) via un ValueNotifier.

import 'package:flutter/material.dart';

class DebugLogUpdater {
        // Array en 3 parties : message, status, valeurs
        final List<String> tempLogBuffer = ["", "", ""];

        // Notifier pour les widgets qui affichent les logs
        final ValueNotifier<List<String>> debugLogsNotifier = ValueNotifier([]);

        // Reconstruit la liste complète de logs en injectant les titres de sections
        void updateLogs() {
                debugLogsNotifier.value = [
                        tempLogBuffer[0],
                        "STATUS",
                        ...tempLogBuffer[1].split('\n').where((line) => line.trim().isNotEmpty),
                        "VALEURS",
                        ...tempLogBuffer[2].split('\n').where((line) => line.trim().isNotEmpty)
                ];
        }

        /// Met à jour un segment du Array (0=message, 1=status, 2=valeurs)
        void setLogChunk(int index, String log) {
                if (index >= 0 && index < tempLogBuffer.length) {
                        tempLogBuffer[index] = log;
                }
        }

        // Accès en lecture seule à la liste courante de logs
        List<String> get debugLogs => debugLogsNotifier.value;
}