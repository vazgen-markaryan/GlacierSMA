import 'sensor_card.dart';
import '../../../constantes.dart';
import 'package:flutter/material.dart';
import '../../../sensors_data/sensors_data.dart';

class Sensors extends StatelessWidget {
        final String title;
        final List<SensorsData> sensors;
        final bool isDebugMode;

        const Sensors({
                super.key,
                required this.title,
                required this.sensors,
                required this.isDebugMode
        });

        @override
        Widget build(BuildContext context) {
                return Column(
                        children: [
                                Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                                Text(title, style: Theme.of(context).textTheme.titleMedium)
                                        ]
                                ),
                                SizedBox(height: defaultPadding),
                                SensorsRow(
                                        sensors: sensors,
                                        isDebugMode: isDebugMode
                                )
                        ]
                );
        }
}

class SensorsRow extends StatelessWidget {
        const SensorsRow({
                super.key,
                required this.sensors,
                required this.isDebugMode
        });

        final List<SensorsData> sensors;
        final bool isDebugMode;

        @override
        Widget build(BuildContext context) {
                return Wrap(
                        spacing: defaultPadding,
                        runSpacing: defaultPadding,
                        children: sensors
                                .where((sensor) => isDebugMode || sensor.powerStatus != null) // Affiche les capteurs null uniquement en mode debug
                                .map(
                                        (sensor) => SizedBox(
                                                width: double.infinity,
                                                height: 100,
                                                child: SensorCard(
                                                        info: sensor,
                                                        isDebugMode: isDebugMode
                                                )
                                        )
                                )
                                .toList()
                );
        }
}