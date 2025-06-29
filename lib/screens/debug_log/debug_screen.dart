import 'debug_log_updater.dart';
import 'debug_log_processor.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';

/// Écran de debug : affiche les logs et les capteurs inactifs piloté par [activeMaskNotifier] pour inclure ceux désactivés.
class DebugScreen extends StatelessWidget {
        final DebugLogUpdater debugLogManager;
        final ValueNotifier<int?> activeMaskNotifier;

        const DebugScreen({
                Key? key,
                required this.debugLogManager,
                required this.activeMaskNotifier
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<int?>(
                        valueListenable: activeMaskNotifier,
                        builder: (context, mask, _) {
                                return Scaffold(
                                        backgroundColor: backgroundColor,
                                        body: SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                DebugLogProcessor(debugLogManager: debugLogManager),

                                                                const SizedBox(height: 32),

                                                                ...createAllSensorGroups(
                                                                        maskNotifier: activeMaskNotifier,
                                                                        getSensors: getSensors,
                                                                        onTap: (context, sensor) => showPopup(context, sensor),
                                                                        configMode: false,
                                                                        showInactive: true,
                                                                        testMode: false
                                                                )
                                                        ]
                                                )
                                        )
                                );
                        }
                );
        }

        void showPopup(BuildContext context, SensorsData sensor) {
                showGeneralDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                        transitionBuilder: (_, animation, __, ___) => Transform.scale(
                                scale: animation.value,
                                alignment: Alignment.center,
                                child: Opacity(
                                        opacity: animation.value,
                                        child: SensorPopup(sensor: sensor)
                                )
                        )
                );
        }
}