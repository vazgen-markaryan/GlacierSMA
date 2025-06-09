import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Représente une anomalie détectée durant le test.
/// Contient le nom du capteur, le nom de la propriété en anomalie, la valeur réelle reçue (`value`), la plage attendue (`minMax`), et l’horodatage de la détection.
class AnomalyRow {
        final String sensorName;
        final String propertyName;
        final String value;
        final String minMax;
        final DateTime timestamp;

        AnomalyRow({
                required this.sensorName,
                required this.propertyName,
                required this.value,
                required this.minMax,
                required this.timestamp
        });
}

/// Widget “BIOS-style” pour afficher une anomalie sous forme de rangée.
/// Affiche l’icône correspondante au DataMap (en rouge pour marquer l’anomalie), le nom du capteur, le nom de la propriété et l’horodatage à gauche, puis la colonne “Attendu / Reçu” à droite.
class AnomalyBIOSRow extends StatelessWidget {
        final String iconPath;
        final String sensorName;
        final String propertyName;
        final String expected;
        final String actual;
        final DateTime timestamp;

        const AnomalyBIOSRow({
                required this.iconPath,
                required this.sensorName,
                required this.propertyName,
                required this.expected,
                required this.actual,
                required this.timestamp,
                Key? key
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                final textTheme = Theme.of(context).textTheme;

                return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                                children: [
                                        // Icône du DataMap (rouge pour signaler l’anomalie)
                                        SvgPicture.asset(
                                                iconPath,
                                                width: 25,
                                                height: 25,
                                                colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn)
                                        ),

                                        const SizedBox(width: 5),

                                        // Capteur + propriété + timestamp
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                // Nom du capteur (en gras, couleur blanche)
                                                                Text(
                                                                        sensorName,
                                                                        style: textTheme.titleMedium
                                                                                ?.copyWith(color: Colors.white)
                                                                ),

                                                                // Propriété + horodatage fusionnés sur une seule ligne
                                                                Text(
                                                                        '$propertyName • ${DateFormat('HH:mm:ss').format(timestamp)}',
                                                                        style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                                                        overflow: TextOverflow.ellipsis
                                                                )
                                                        ]
                                                )
                                        ),

                                        const SizedBox(width: 5),

                                        // Colonne “Attendu / Reçu” alignée à droite
                                        Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                        // “Attendu: (min : max)” en jaune
                                                        Text(
                                                                '${tr('test.selected')}: $expected',
                                                                style: textTheme.bodyMedium?.copyWith(color: Colors.amberAccent)
                                                        ),

                                                        // “Reçu: valeur” en rouge gras
                                                        Text(
                                                                '${tr('test.received')}: $actual',
                                                                style: textTheme.bodyMedium
                                                                        ?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)
                                                        )
                                                ]
                                        )
                                ]
                        )
                );
        }
}

/// Construit une colonne de widgets AnomalyBIOSRow pour chaque anomalie de la liste `anomalies`.
/// - `ranges` : La map des plages actuelles par capteur/DataMap (utilisée pour retrouver l’icône).
/// - `anomalies` : Liste des anomalies à afficher.
/// Pour chaque `AnomalyRow`, on recherche le DataMap correspondant via son `propertyName`,on en extrait l’icône SVG, et on crée une AnomalyBIOSRow.
Widget anomalyBIOSList(
        Map<SensorsData, Map<DataMap, RangeValues>> ranges,
        List<AnomalyRow> anomalies
) {
        // Fonction interne pour retrouver l’objet DataMap correspondant à `propertyName`
        DataMap? findDataMapByName(
                String propertyName,
                Map<SensorsData, Map<DataMap, RangeValues>> ranges
        ) {
                for (final sensor in ranges.keys) {
                        for (final key in sensor.data.keys) {
                                // Compare le nom localisé (tr(key.name)) ou le header brut
                                if (tr(key.name) == propertyName || key.name == propertyName) {
                                        return key;
                                }
                        }
                }
                return null;
        }

        return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: anomalies.map(
                        (anomaly) {
                                // Pour chaque anomalie, retrouver le DataMap pour afficher l’icône appropriée
                                final dataMap = findDataMapByName(anomaly.propertyName, ranges);
                                final iconPath = dataMap?.svgLogo ?? microchip;

                                // Crée une AnomalyBIOSRow avec les données de l’anomalie
                                return AnomalyBIOSRow(
                                        iconPath: iconPath,
                                        sensorName: anomaly.sensorName,
                                        propertyName: anomaly.propertyName,
                                        expected: anomaly.minMax,
                                        actual: anomaly.value,
                                        timestamp: anomaly.timestamp
                                );
                        }
                ).toList()
        );
}

/// Parcourt toutes les valeurs “réelles” (`realValues`) et les compare aux plages autorisées (`ranges`).
/// Pour chaque entrée où `real` est hors plage (`< start` ou `> end`), on crée un AnomalyRow.
/// - `ranges` : Map des plages actuelles par capteur/DataMap.
/// - `realValues` : Map des valeurs réelles reçues par capteur/DataMap.
/// Retourne la liste d’AnomalyRow détectées durant ce passage.
List<AnomalyRow> detectAnomalies(
        Map<SensorsData, Map<DataMap, RangeValues>> ranges,
        Map<SensorsData, Map<DataMap, double>> realValues
) {
        final List<AnomalyRow> anomalies = [];

        // Parcourt chaque capteur de `ranges`
        for (var sensor in ranges.keys) {
                final currentRanges = ranges[sensor]!;
                final realVals = realValues[sensor] ?? {};

                // Parcourt chaque DataMap du capteur
                for (var k in currentRanges.keys) {
                        final range = currentRanges[k]!;
                        final real = realVals[k];

                        // Si une valeur réelle existe et sort de la plage autorisée, on détecte une anomalie
                        if (real != null && (real < range.start || real > range.end)) {
                                anomalies.add(
                                        AnomalyRow(
                                                // Nom du capteur + placement seulement pour les capteurs de type thermo-baromètre
                                                // Utilise le header pour distinguer les capteurs BME280 (intérieur/extérieur)
                                                // Utilise la clé `placement` traduite pour afficher [MB] ou [I2C]
                                                sensorName: '${tr(sensor.title ?? '')}${(sensor.header == "mb_bme280_status" || sensor.header == "bme280_status") ? ((tr(sensor.placement ?? '') == tr("sensor-data.placement.exterior")) ? ' [MB]' : ' [I2C]') : ''}',
                                                // Nom localisé de la propriété
                                                propertyName: tr(k.name),
                                                // Valeur réelle formatée avec unité
                                                value: '${real.toStringAsFixed(1)} ${getUnitForHeader(k.header)}',
                                                // Représentation texte de la plage attendue (min : max)
                                                minMax: '(${range.start.toInt()} : ${range.end.toInt()})',
                                                timestamp: DateTime.now()
                                        )
                                );
                        }
                }
        }

        return anomalies;
}