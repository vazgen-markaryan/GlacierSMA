/// Affiche le timestamp actuel et la liste des données du capteur.
/// Utilise un ValueListenableBuilder pour réagir dynamiquement aux changements de données.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

class SensorPopupBody extends StatelessWidget {
        /// Capteur dont on affiche les données
        final SensorsData sensor;

        /// Timestamp à afficher en haut du bloc (mis à jour chaque seconde)
        final String timestamp;

        const SensorPopupBody({
                super.key,
                required this.sensor,
                required this.timestamp
        });

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.all(12), // Padding réduit
                        child: Scrollbar(
                                thumbVisibility: true,
                                radius: const Radius.circular(8),
                                thickness: 6,
                                child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: SingleChildScrollView(
                                                child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                        valueListenable: sensor.dataNotifier,
                                                        builder: (_, data, __) {
                                                                final items = data.entries.toList();

                                                                return Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                                // Timestamp de dernière mise à jour
                                                                                Text(
                                                                                        'Mise à jour : $timestamp',
                                                                                        style: const TextStyle(
                                                                                                color: Colors.white54,
                                                                                                fontSize: 16,
                                                                                                fontStyle: FontStyle.italic
                                                                                        )
                                                                                ),
                                                                                const SizedBox(height: 12),

                                                                                // Données capteur
                                                                                ...items.map((e) => buildRow(e.key, e.value)).toList()
                                                                        ]
                                                                );
                                                        }
                                                )
                                        )
                                )
                        )
                );
        }

        /// Construit une ligne contenant : icône + nom à gauche, valeur à droite
        Widget buildRow(DataMap key, dynamic value) {
                return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                        // Icône + nom
                                        Row(
                                                children: [
                                                        SvgPicture.asset(
                                                                key.svgLogo,
                                                                height: 24,
                                                                width: 24,
                                                                colorFilter:
                                                                const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                                key.name,
                                                                style: const TextStyle(color: Colors.white70, fontSize: 15)
                                                        )
                                                ]
                                        ),

                                        // Valeur numérique ou textuelle alignée à droite
                                        Flexible(
                                                child: Text(
                                                        value.toString(),
                                                        style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold
                                                        ),
                                                        textAlign: TextAlign.right,
                                                        overflow: TextOverflow.ellipsis
                                                )
                                        )
                                ]
                        )
                );
        }
}