import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

/// Retourne le libellé traduit correspondant à un code de statut
String statusLabel(int status) {
        switch (status) {
                case 1: return tr('debug.status_operational');
                case 2: return tr('debug.status_disconnected');
                case 3: return tr('debug.status_error');
                case 0:
                default:
                return tr('debug.status_unknown');
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
                        // Écoute le notifier des logs
                        valueListenable: debugLogManager.debugLogsNotifier,
                        builder: (context, logs, _) {
                                final statusRows = <TableRow>[];
                                final valeurRows = <TableRow>[];
                                bool isInStatus = false, isInValeurs = false;

                                for (var line in logs) {
                                        final trimmed = line.trim();
                                        final lower = trimmed.toLowerCase();

                                        // Repère les switches de section (dans la langue d’origine)
                                        if (lower == 'status' || lower == tr('debug.section_status').toLowerCase()) {
                                                isInStatus = true;
                                                isInValeurs = false;
                                                continue;
                                        }
                                        if (lower == 'valeurs' || lower == tr('debug.section_values').toLowerCase()) {
                                                isInStatus = false;
                                                isInValeurs = true;
                                                continue;
                                        }

                                        if (trimmed.isEmpty || !trimmed.contains(':')) continue;
                                        final parts = trimmed.split(':');
                                        if (parts.length < 2) continue;
                                        final key = parts[0].trim();
                                        final rawValue = parts.sublist(1).join(':').trim();

                                        // Ne pas recréer une ligne pour les titres de section
                                        if (isSectionTitle(key)) continue;

                                        // Construit le widget de valeur
                                        Widget valueWidget;
                                        if (isInStatus) {
                                                // STATUS → "2 (Déconnecté)"
                                                final code = int.tryParse(rawValue) ?? -1;
                                                final label = statusLabel(code);
                                                valueWidget = Text(
                                                        '$code ($label)',
                                                        style: const TextStyle(fontSize: 12)
                                                );
                                        }
                                        else {
                                                // VALEURS → override Iridium ou brut
                                                if (key.toLowerCase() == 'iridium_signal_quality') {
                                                        final quality = int.tryParse(rawValue) ?? -1;
                                                        final map = getIridiumSvgLogoAndColor(quality);
                                                        final label = map['value'] as String;
                                                        valueWidget = Text(
                                                                '$quality ($label)',
                                                                style: const TextStyle(fontSize: 12)
                                                        );
                                                }
                                                else {
                                                        valueWidget = Text(
                                                                rawValue,
                                                                style: const TextStyle(fontSize: 12)
                                                        );
                                                }
                                        }

                                        final row = TableRow(
                                                children: [
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                child: Text(key, style: const TextStyle(fontSize: 12))
                                                        ),
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                child: Align(alignment: Alignment.centerRight, child: valueWidget)
                                                        )
                                                ]
                                        );

                                        if (isInStatus) statusRows.add(row);
                                        if (isInValeurs) valeurRows.add(row);
                                }

                                final sentPrefix = tr('debug.message_sent', namedArgs: {'log': ''}).toLowerCase();
                                final errPrefix = tr('debug.message_error', namedArgs: {'log': ''}).toLowerCase();

                                return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SizedBox(
                                                width: double.infinity,
                                                child: Card(
                                                        margin: EdgeInsets.zero,
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(12.0),
                                                                child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                                // Affiche le premier message "message envoyé", s'il y en a un
                                                                                Text(
                                                                                        logs.firstWhere(
                                                                                                (line) {
                                                                                                        final l = line.toLowerCase();
                                                                                                        return l.startsWith(sentPrefix) || l.startsWith(errPrefix);
                                                                                                },
                                                                                                orElse: () => ''
                                                                                        ),
                                                                                        style: const TextStyle(fontSize: 12)
                                                                                ),
                                                                                const SizedBox(height: 8),

                                                                                // Section STATUS
                                                                                Align(
                                                                                        alignment: Alignment.center,
                                                                                        child: Text(
                                                                                                tr('debug.section_status'),
                                                                                                style: Theme.of(context).textTheme.titleMedium
                                                                                        )
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
                                                                                buildEmptyMessage(context),

                                                                                const SizedBox(height: 16),

                                                                                // Section VALEURS
                                                                                Align(
                                                                                        alignment: Alignment.center,
                                                                                        child: Text(
                                                                                                tr('debug.section_values'),
                                                                                                style: Theme.of(context).textTheme.titleMedium
                                                                                        )
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
                                                                                buildEmptyMessage(context)
                                                                        ]
                                                                )
                                                        )
                                                )
                                        )
                                );
                        }
                );
        }

        /// Titre de section à ignorer
        bool isSectionTitle(String key) {
                final low = key.toLowerCase();
                return low == 'status' || low == tr('debug.section_status').toLowerCase() || low == 'valeurs' || low == tr('debug.section_values').toLowerCase();
        }

        /// Widget affiché quand aucune ligne n’existe
        Widget buildEmptyMessage(BuildContext context) => Align(
                alignment: Alignment.center,
                child: Text(
                        tr('debug.no_data_received'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall
                )
        );
}