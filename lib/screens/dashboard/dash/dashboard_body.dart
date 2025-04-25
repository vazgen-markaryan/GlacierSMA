/// Corps du Dashboard : logs debug et groupes de capteurs.

import 'dart:typed_data';
import '../utils/constants.dart';
import '../sensors/sensors_data.dart';
import 'package:flutter/material.dart';
import '../sensors/sensors_group.dart';
import '../debug/debug_data_parser.dart';
import '../debug/debug_log_manager.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/dash/send_message_button.dart';

class DashboardBody extends StatelessWidget {
        final bool isDebugVisible;
        final DebugLogManager debugLogManager;
        final List<SensorsData> Function(SensorType) getSensors;
        final Future<bool> Function(String, Uint8List) sendCustomMessage;

        const DashboardBody({
                super.key,
                required this.isDebugVisible,
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
                                        if (isDebugVisible)
                                        DebugData(debugLogManager: debugLogManager),
                                        const SizedBox(height: defaultPadding),

                                        SensorsGroup(
                                                title: 'Capteurs Internes',
                                                sensors: getSensors(SensorType.internal),
                                                isDebugMode: isDebugVisible
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        SensorsGroup(
                                                title: 'Capteurs ModBus',
                                                sensors: getSensors(SensorType.modbus),
                                                isDebugMode: isDebugVisible
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        SensorsGroup(
                                                title: 'Capteurs Stevenson',
                                                sensors: getSensors(SensorType.stevensonStatus).first.powerStatus == 2
                                                        ? getSensors(SensorType.stevensonStatus)
                                                        : getSensors(SensorType.stevenson),
                                                isDebugMode: isDebugVisible
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        SendMessageButton(sendCustomMessage: sendCustomMessage)
                                ]
                        )
                );
        }
}