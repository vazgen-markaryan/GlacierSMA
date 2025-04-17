import 'package:rev_glacier_sma_mobile/screens/dashboard/components/sensor_card.dart';
import '../../../constants.dart';
import 'package:flutter/material.dart';
import 'sensors_data.dart';

/// Notifie lorsque n'importe quel capteur du groupe change
class SensorsGroupNotifier extends ValueNotifier<int> {
        SensorsGroupNotifier(List<SensorsData> sensors) : super(0) {
                for (var sensor in sensors) {
                        sensor.dataNotifier.addListener(_onChange);
                }
        }

        void _onChange() => value++;
}

/// Affiche un groupe de capteurs avec un titre
class SensorsDiv extends StatelessWidget {
        final String title;
        final List<SensorsData> sensors;
        final bool isDebugMode;

        const SensorsDiv({
                super.key,
                required this.title,
                required this.sensors,
                required this.isDebugMode
        });

        @override
        Widget build(BuildContext context) {
                final notifier = SensorsGroupNotifier(sensors);

                return ValueListenableBuilder<int>(
                        valueListenable: notifier,
                        builder: (context, _, __) {
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
                );
        }
}

/// Affiche une rangée de cartes de capteurs
class SensorsRow extends StatelessWidget {
        final List<SensorsData> sensors;
        final bool isDebugMode;

        const SensorsRow({
                super.key,
                required this.sensors,
                required this.isDebugMode
        });

        @override
        Widget build(BuildContext context) {
                final filteredSensors = sensors.where(
                        (sensor) => isDebugMode || sensor.powerStatus != null
                );

                return Wrap(
                        spacing: defaultPadding,
                        runSpacing: defaultPadding,
                        children: filteredSensors.map(
                                (sensor) => SizedBox(
                                        width: double.infinity,
                                        height: 100,
                                        child: SensorCard(
                                                sensorData: sensor,
                                                isDebugMode: isDebugMode
                                        )
                                )
                        ).toList()
                );
        }
}