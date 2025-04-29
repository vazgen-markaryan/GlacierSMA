/// Affiche les logs de STATUS et VALEURS dans un tableau stylisé
/// - Formate les codes de statut en labels lisibles (e.g. “1 (Fonctionne)”)
/// - Met à jour automatiquement lorsque DebugLogManager diffuse de nouvelles lignes

import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

/// Retourne le libellé correspondant à un code de statut
String statusLabel(int status) {
        switch (status) {
                case 1:
                        return 'Fonctionne';
                case 2:
                        return 'Déconnecté';
                case 3:
                        return 'Erreur';
                case 0:
                default:
                return 'Inconnu';
        }
}

/// Widget qui affiche deux sections :
///  • STATUS : liste des capteurs et leur code+label
///  • VALEURS : liste des mesures brutes
class DebugLogProcessor extends StatelessWidget {
        final DebugLogUpdater debugLogManager;

        const DebugLogProcessor({Key? key, required this.debugLogManager}) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<List<String>>(
                        // Écoute le notifier qui contient la liste de toutes les lignes de log
                        valueListenable: debugLogManager.debugLogsNotifier,
                        builder: (context, logs, _) {
                                // Prépare deux listes de TableRow pour STATUS et VALEURS
                                final List<TableRow> statusRows = [];
                                final List<TableRow> valeurRows = [];
                                bool isInStatus = false;
                                bool isInValeurs = false;

                                for (var line in logs) {
                                        final trimmedLine = line.trim();
                                        final lower = trimmedLine.toLowerCase();

                                        // Basculer entre section STATUS et VALEURS
                                        if (lower == 'status') {
                                                isInStatus = true;
                                                isInValeurs = false;
                                                continue;
                                        }
                                        if (lower == 'valeurs') {
                                                isInStatus = false;
                                                isInValeurs = true;
                                                continue;
                                        }

                                        // Ignorer les lignes vides ou n'ayant pas de séparateur ':'
                                        if (trimmedLine.isEmpty || !trimmedLine.contains(':')) continue;

                                        // Séparer en clé et valeur
                                        final parts = trimmedLine.split(':');
                                        if (parts.length < 2) continue;
                                        final key = parts[0].trim();
                                        final rawValue = parts.sublist(1).join(':').trim();

                                        // Ne pas recréer une ligne pour les titres de section
                                        if (isSectionTitle(key)) continue;

                                        // Choisir l’affichage selon la section
                                        Widget valueWidget;
                                        if (isInStatus) {
                                                // Pour STATUS : convertir code en label
                                                final code = int.tryParse(rawValue) ?? -1;
                                                final label = statusLabel(code);
                                                valueWidget = Text(
                                                        '$code ($label)',
                                                        style: const TextStyle(fontSize: 12)
                                                );
                                        }
                                        else {
                                                // Pour VALEURS : afficher la valeur brute
                                                valueWidget = Text(
                                                        rawValue,
                                                        style: const TextStyle(fontSize: 12)
                                                );
                                        }

                                        // Créer une ligne de tableau avec clé à gauche et valeur alignée à droite
                                        final row = TableRow(children: [
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                child: Text(key, style: const TextStyle(fontSize: 12))
                                                        ),
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                child: Align(
                                                                        alignment: Alignment.centerRight,
                                                                        child: valueWidget
                                                                )
                                                        )
                                                ]);

                                        // Ajouter la ligne à la section appropriée
                                        if (isInStatus) {
                                                statusRows.add(row);
                                        }
                                        else if (isInValeurs) {
                                                valeurRows.add(row);
                                        }
                                }

                                // Construire l’UI : titre, tableau STATUS, puis tableau VALEURS
                                return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Card(
                                                child: Padding(
                                                        padding: const EdgeInsets.all(12.0),
                                                        child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        // Affiche le premier message contenant "message envoyé", le cas échéant
                                                                        Text(
                                                                                logs.firstWhere(
                                                                                        (l) => l.toLowerCase().contains('message envoyé'),
                                                                                        orElse: () => ''
                                                                                ),
                                                                                style: const TextStyle(fontSize: 12)
                                                                        ),
                                                                        const SizedBox(height: 16),

                                                                        // Section STATUS
                                                                        const Text(
                                                                                'STATUS',
                                                                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)
                                                                        ),
                                                                        const SizedBox(height: 8),
                                                                        if (statusRows.isNotEmpty)
                                                                        Table(
                                                                                columnWidths: const {
                                                                                        0: IntrinsicColumnWidth(),
                                                                                        1: FlexColumnWidth()
                                                                                },
                                                                                border: TableBorder.all(color: Colors.grey),
                                                                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                                                                children: statusRows
                                                                        )
                                                                        else
                                                                        const Text('Aucune donnée.', style: TextStyle(fontSize: 12)),
                                                                        const SizedBox(height: 16),

                                                                        // Section VALEURS
                                                                        const Text(
                                                                                'VALEURS',
                                                                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)
                                                                        ),
                                                                        const SizedBox(height: 8),
                                                                        if (valeurRows.isNotEmpty)
                                                                        Table(
                                                                                columnWidths: const {
                                                                                        0: IntrinsicColumnWidth(),
                                                                                        1: FlexColumnWidth()
                                                                                },
                                                                                border: TableBorder.all(color: Colors.grey),
                                                                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                                                                children: valeurRows
                                                                        )
                                                                        else
                                                                        const Text('Aucune donnée.', style: TextStyle(fontSize: 12))
                                                                ]
                                                        )
                                                )
                                        )
                                );
                        }
                );
        }

        /// Retourne vrai si [key] correspond à un titre de section ("status" ou "valeurs")
        bool isSectionTitle(String key) {
                final low = key.toLowerCase();
                return low == 'status' || low == 'valeurs';
        }
}