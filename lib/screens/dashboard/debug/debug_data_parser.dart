/// debug_data_parser.dart
/// Affiche les logs de debug (STATUS et VALEURS) dans un tableau,
/// en écoutant les mises à jour de DebugLogManager via un ValueNotifier.

import 'debug_log_manager.dart';
import 'package:flutter/material.dart';

class DebugData extends StatelessWidget {
        final DebugLogManager debugLogManager;

        const DebugData({
                super.key,
                required this.debugLogManager
        });

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<List<String>>(

                        // Écoute du notifier contenant la liste de toutes les lignes de log
                        valueListenable: debugLogManager.debugLogsNotifier,
                        builder: (context, logs, _) {

                                // Préparation des lignes pour les sections STATUS et VALEURS
                                final List<TableRow> statusRows = [];
                                final List<TableRow> valeurRows = [];
                                bool isInStatus = false;
                                bool isInValeurs = false;

                                for (var line in logs) {
                                        final trimmedLine = line.trim();
                                        final lowerLine = trimmedLine.toLowerCase();

                                        // Détection des titres de sections
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

                                        // Ignorer les lignes vides ou sans “:”
                                        if (trimmedLine.isEmpty || !trimmedLine.contains(':')) continue;

                                        // Séparation clé : valeur
                                        final parts = trimmedLine.split(':');
                                        if (parts.length < 2) continue;
                                        final key = parts[0].trim();
                                        final value = parts.sublist(1).join(':').trim();

                                        // Éviter de réinclure les titres comme données
                                        if (key.toLowerCase() == "status" || key.toLowerCase() == "valeurs") continue;

                                        // Création de la ligne de tableau
                                        final row = TableRow(
                                                children: [
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

                                        // Ajout à la bonne section
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
                                                                        // Affiche la première ligne contenant “message envoyé” si présente
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
                                                                        // Tableau des données de statut
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
                                                                        const Text("Aucune donnée."),
                                                                        const SizedBox(height: 16),
                                                                        const Text("VALEURS", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                                                                        const SizedBox(height: 8),

                                                                        // Tableau des valeurs
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
                                                                        const Text("Aucune donnée.")
                                                                ]
                                                        )
                                                )
                                        )
                                );
                        }
                );
        }
}