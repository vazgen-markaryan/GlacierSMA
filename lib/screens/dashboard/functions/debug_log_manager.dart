import 'package:flutter/material.dart';

class DebugLogManager {
        final List<String> tempLogBuffer = ["", "", ""];
        final ValueNotifier<List<String>> debugLogsNotifier = ValueNotifier([]);

        void updateLogs() {
                debugLogsNotifier.value = [
                        tempLogBuffer[0],
                        "STATUS",
                        ...tempLogBuffer[1].split('\n').where((line) => line.trim().isNotEmpty),
                        "VALEURS",
                        ...tempLogBuffer[2].split('\n').where((line) => line.trim().isNotEmpty)
                ];
        }

        void setLogChunk(int index, String log) {
                if (index >= 0 && index < tempLogBuffer.length) {
                        tempLogBuffer[index] = log;
                }
        }

        List<String> get debugLogs => debugLogsNotifier.value;
}