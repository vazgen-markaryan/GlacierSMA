import 'sensor_card.dart';
import '../../../constantes.dart';
import 'package:flutter/material.dart';
import '../../../sensors_data/sensors_data.dart';

class MySensors extends StatelessWidget {
        final String title;
        final List<Sensors> sensors;
        final bool isDebugMode;

        const MySensors({
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

        final List<Sensors> sensors;
        final bool isDebugMode;

        @override
        Widget build(BuildContext context) {
                return Wrap(
                        spacing: defaultPadding,
                        runSpacing: defaultPadding,
                        children: sensors
                                .where((sensor) => sensor.powerStatus != null) // Filtrer les capteurs avec powerStatus != null
                                .map((sensor) {
                                                return SizedBox(
                                                        width: double.infinity,
                                                        height: 100,
                                                        child: SensorCard(info: sensor, isDebugMode: isDebugMode)
                                                );
                                        }
                                ).toList()
                );
        }
}