import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

class DashboardBody extends StatelessWidget {
        final DebugLogUpdater debugLogManager;
        final List<SensorsData> Function(SensorType) getSensors;

        const DashboardBody({
                super.key,
                required this.debugLogManager,
                required this.getSensors
        });

        @override
        Widget build(BuildContext context) {
                // 1️⃣ On récupère d’abord le statut du bridge Stevenson
                final steStatus = getSensors(SensorType.stevensonStatus).first.powerStatus;

                // 2️⃣ On décide quels capteurs afficher :
                //    • si steStatus == 1, on affiche les 2 capteurs BME280 et VEML7700
                //    • sinon on n’affiche que la carte de statut (stevensonStatus)
                final stevensonSensorsToShow = (steStatus == 1)
                        ? getSensors(SensorType.stevenson)
                        : getSensors(SensorType.stevensonStatus);

                return SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        // Capteurs internes
                                        SensorsGroup(
                                                title: 'Capteurs Internes',
                                                sensors: getSensors(SensorType.internal)
                                                        .where((s) => s.powerStatus != null)
                                                        .toList()
                                        ),

                                        const SizedBox(height: defaultPadding),

                                        // Capteurs ModBus
                                        SensorsGroup(
                                                title: 'Capteurs ModBus',
                                                sensors: getSensors(SensorType.modbus)
                                                        .where((s) => s.powerStatus != null)
                                                        .toList()
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        // Capteurs Stevenson, avec la logique conditionnelle
                                        SensorsGroup(
                                                title: 'Les Capteurs Stevenson',
                                                sensors: stevensonSensorsToShow
                                                        .where((s) => s.powerStatus != null)
                                                        .toList()
                                        )
                                ]
                        )
                );
        }
}