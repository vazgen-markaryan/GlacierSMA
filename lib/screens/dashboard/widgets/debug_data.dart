import 'package:flutter/material.dart';
import '../functions/debug_log_manager.dart';

class DebugData extends StatelessWidget {
        final DebugLogManager debugLogManager;

        const DebugData({
                super.key,
                required this.debugLogManager
        });

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<List<String>>(
                        valueListenable: debugLogManager.debugLogsNotifier,
                        builder: (context, logs, _) {
                                final List<TableRow> statusRows = [];
                                final List<TableRow> valeurRows = [];
                                bool isInStatus = false;
                                bool isInValeurs = false;

                                for (var line in logs) {
                                        final trimmedLine = line.trim();
                                        final lowerLine = trimmedLine.toLowerCase();

                                        if (lowerLine == "status") {
                                                isInStatus = true;
                                                isInValeurs = false;
                                                continue;
                                        }

                                        if (lowerLine == "valeurs") {
                                                isInStatus = false;
                                                isInValeurs = true;
                                                continue;
                                        }

                                        if (trimmedLine.isEmpty || !trimmedLine.contains(':')) continue;

                                        final parts = trimmedLine.split(':');
                                        if (parts.length < 2) continue;

                                        final key = parts[0].trim();
                                        final value = parts.sublist(1).join(':').trim();

                                        // Éviter d'inclure des lignes contenant uniquement "status" ou "valeurs" comme noms
                                        if (key.toLowerCase() == "status" || key.toLowerCase() == "valeurs") continue;

                                        final row = TableRow(children: [
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                child: Text(key, style: const TextStyle(fontSize: 14))
                                                        ),
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                child: Align(
                                                                        alignment: Alignment.centerRight,
                                                                        child: Text(value, style: const TextStyle(fontSize: 14))
                                                                )
                                                        )
                                                ]);

                                        if (isInStatus) {
                                                statusRows.add(row);
                                        }
                                        else if (isInValeurs) {
                                                valeurRows.add(row);
                                        }
                                }

                                return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Card(
                                                child: Padding(
                                                        padding: const EdgeInsets.all(12.0),
                                                        child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        Text(
                                                                                logs.firstWhere(
                                                                                        (line) => line.toLowerCase().contains("message envoyé"),
                                                                                        orElse: () => ""
                                                                                ),
                                                                                style: const TextStyle(fontSize: 14)
                                                                        ),
                                                                        const SizedBox(height: 16),
                                                                        const Text("STATUS", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                                                                        const SizedBox(height: 8),
                                                                        if (statusRows.isNotEmpty)
                                                                        Table(
                                                                                columnWidths: const {
                                                                                        0: IntrinsicColumnWidth(),
                                                                                        1: FlexColumnWidth()
                                                                                },
                                                                                border: TableBorder.all(color: Colors.grey.shade300),
                                                                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                                                                children: statusRows
                                                                        )
                                                                        else
                                                                        const Text("Aucune donnée de statut."),
                                                                        const SizedBox(height: 16),
                                                                        const Text("VALEURS", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                                                                        const SizedBox(height: 8),
                                                                        if (valeurRows.isNotEmpty)
                                                                        Table(
                                                                                columnWidths: const {
                                                                                        0: IntrinsicColumnWidth(),
                                                                                        1: FlexColumnWidth()
                                                                                },
                                                                                border: TableBorder.all(color: Colors.grey.shade300),
                                                                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                                                                children: valeurRows
                                                                        )
                                                                        else
                                                                        const Text("Aucune donnée de valeur.")
                                                                ]
                                                        )
                                                )
                                        )
                                );
                        }
                );
        }
}