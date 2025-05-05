import 'sensors_data.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

typedef SensorItemBuilder = Widget Function(BuildContext context, SensorsData sensor);

/// Affiche :
///  • un titre centré,
///  • soit une grille de capteurs via [itemBuilder],
///  • soit [emptyMessage] si la liste est vide,
/// le tout avec un spacing cohérent.
class SensorsGroup extends StatelessWidget {
        /// Titre à centrer au-dessus de la grille.
        final String title;

        /// Liste des capteurs à afficher.
        final List<SensorsData> sensors;

        /// Comment construire chaque carte.
        final SensorItemBuilder itemBuilder;

        /// Texte à afficher si [sensors] est vide.
        final String emptyMessage;

        const SensorsGroup({
                Key? key,
                required this.title,
                required this.sensors,
                required this.itemBuilder,
                this.emptyMessage = 'Aucun capteur actif\nVérifiez votre Configuration'
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Column(
                        children: [
                                // Le titre centré
                                Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                                title,
                                                style: Theme.of(context).textTheme.titleMedium
                                        )
                                ),

                                // Soit la grille, soit le message "vide"
                                if (sensors.isNotEmpty)
                                Wrap(
                                        spacing: defaultPadding,
                                        runSpacing: defaultPadding,
                                        children: sensors.map((s) => itemBuilder(context, s)).toList()
                                )
                                else
                                Padding(
                                        padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                                        child: Text(
                                                emptyMessage,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.bodyMedium
                                        )
                                ),

                                const SizedBox(height: defaultPadding)
                        ]
                );
        }
}