import 'sensors_data.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

typedef SensorItemBuilder = Widget Function(BuildContext context, SensorsData sensor);

/// Affiche :
///  • un titre centré,
///  • soit une grille de capteurs via [itemBuilder],
///  • soit [emptyMessage] si la liste est vide,
/// le tout avec un spacing cohérent.
class SensorsGroup extends StatelessWidget {

        final String title;
        final List<SensorsData> sensors;
        final SensorItemBuilder itemBuilder;
        final String emptyMessage;

        const SensorsGroup({
                Key? key,
                required this.title,
                required this.sensors,
                required this.itemBuilder,
                this.emptyMessage = 'dashboard.sensors.empty_active'
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Column(
                        children: [
                                Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                                tr(title),
                                                style: Theme.of(context).textTheme.titleMedium
                                        )
                                ),

                                const SizedBox(height: 16),

                                // Soit la grille, soit le message "vide"
                                if (sensors.isNotEmpty)
                                Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: sensors.map((sensor) => itemBuilder(context, sensor)).toList()
                                )
                                else
                                Text(
                                        tr(emptyMessage),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium
                                ),

                                const SizedBox(height: 16)
                        ]
                );
        }
}