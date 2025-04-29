/// Corps du Dashboard : logs components et groupes de capteurs.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/components/debug_log_updater.dart';

class DashboardBody extends StatelessWidget {
        final DebugLogUpdater debugLogManager;
        final List<SensorsData> Function(SensorType) getSensors;
        final Future<bool> Function(String, Uint8List) sendCustomMessage;

        const DashboardBody({
                super.key,
                required this.debugLogManager,
                required this.getSensors,
                required this.sendCustomMessage
        });

        @override
        Widget build(BuildContext context) {
                return SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        SensorsGroup(
                                                title: 'Capteurs Internes',
                                                sensors: getSensors(SensorType.internal)
                                                        .where((s) => s.powerStatus != null)
                                                        .toList()
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        SensorsGroup(
                                                title: 'Capteurs ModBus',
                                                sensors: getSensors(SensorType.modbus)
                                                        .where((s) => s.powerStatus != null)
                                                        .toList()
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        SensorsGroup(
                                                title: 'Capteurs Stevenson',
                                                sensors: getSensors(SensorType.stevensonStatus).first.powerStatus == 2
                                                        ? getSensors(SensorType.stevensonStatus)
                                                        : getSensors(SensorType.stevenson)
                                                                .where((s) => s.powerStatus != null)
                                                                .toList()
                                        )
                                ]
                        )
                );
        }
}