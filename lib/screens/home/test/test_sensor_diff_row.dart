import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Widget affichant une ligne “BIOS-style” décrivant la différence d’un seul paramètre (DataMap) pour un capteur donné.
/// Montre l’icône du DataMap, le nom du capteur et de la propriété, puis la valeur “Avant” (défaut) et “Après” (valeur modifiée), chacune préfixée par un label localisé.
class TestSensorDiffRow extends StatelessWidget {
        final String iconPath;
        final String propertyName;
        final String sensorName;
        final String before;
        final String after;

        const TestSensorDiffRow({
                required this.iconPath,
                required this.propertyName,
                required this.sensorName,
                required this.before,
                required this.after,
                Key? key
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                                children: [
                                        // Icône du DataMap, affichée à gauche
                                        SvgPicture.asset(
                                                iconPath,
                                                width: 28,
                                                height: 28,
                                                colorFilter: const ColorFilter.mode(
                                                        Colors.white70,
                                                        BlendMode.srcIn
                                                )
                                        ),
                                        const SizedBox(width: 10),

                                        // Colonne contenant le nom du capteur (en gras) et de la propriété
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                // Nom du capteur (ex. “BME280”)
                                                                Text(
                                                                        sensorName,
                                                                        style: const TextStyle(
                                                                                color: Colors.white,
                                                                                fontWeight: FontWeight.bold
                                                                        )
                                                                ),
                                                                // Nom de la propriété (ex. “Temperature (°C)”)
                                                                Text(
                                                                        propertyName,
                                                                        style: const TextStyle(
                                                                                color: Colors.white70,
                                                                                fontSize: 13
                                                                        )
                                                                )
                                                        ]
                                                )
                                        ),
                                        const SizedBox(width: 10),

                                        // Colonne alignée à droite affichant “Défaut: before” puis “Après: after”
                                        Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                        // Première ligne : label “Défaut” (localisé) + valeur “before”
                                                        Container(
                                                                margin: const EdgeInsets.only(right: 10),
                                                                child: Text(
                                                                        tr("test.default") + ": $before",
                                                                        style: const TextStyle(
                                                                                color: Colors.white54,
                                                                                fontSize: 13
                                                                        )
                                                                )
                                                        ),
                                                        // Deuxième ligne : label “Après” (localisé) + valeur “after”
                                                        Container(
                                                                margin: const EdgeInsets.only(right: 10),
                                                                child: Text(
                                                                        tr("test.after") + ": $after",
                                                                        style: const TextStyle(
                                                                                color: Colors.amber,
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 13
                                                                        )
                                                                )
                                                        )
                                                ]
                                        )
                                ]
                        )
                );
        }
}

/// Construit une liste de widgets TestSensorDiffRow pour chaque différence détectée entre les plages actuelles (`ranges`) et les plages par défaut (`defaultRanges`).
/// Parcourt chaque capteur et chaque DataMap, compare `ranges[sensor][key]` à `defaultRanges[sensor][key]`, et ajoute une ligne pour chaque paramètre modifié.
List<Widget> buildDiffs(
        Map<SensorsData, Map<DataMap, RangeValues>> ranges,
        Map<SensorsData, Map<DataMap, RangeValues>> defaultRanges
) {
        final List<Widget> diffs = [];
        // Boucle sur chaque capteur
        for (var sensor in ranges.keys) {
                final current = ranges[sensor]!;
                final defaults = defaultRanges[sensor]!;
                // Boucle sur chaque DataMap du capteur
                for (var k in current.keys) {
                        final def = defaults[k]!;
                        final cur = current[k]!;
                        // Si la plage par défaut diffère de la plage actuelle, on ajoute une ligne
                        if (def != cur) {
                                diffs.add(
                                        TestSensorDiffRow(
                                                iconPath: k.svgLogo,
                                                // Nom de la propriété + unité
                                                propertyName: '${tr(k.name)} (${getUnitForHeader(k.header)})',
                                                sensorName: tr(sensor.title ?? ''),
                                                // Format “min / max” pour Avant et Après
                                                before: '${def.start.toInt()} / ${def.end.toInt()}',
                                                after: '${cur.start.toInt()} / ${cur.end.toInt()}'
                                        )
                                );
                        }
                }
        }
        return diffs;
}