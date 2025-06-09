import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';

/// Corps du tableau de bord : affiche les capteurs **activés** selon la config
/// Se met à jour instantanément sur `activeMaskNotifier`.
class DashboardBody extends StatelessWidget {
        final List<SensorsData> Function(SensorType) getSensors;
        final ValueListenable<int?> activeMaskNotifier;

        const DashboardBody({
                Key? key,
                required this.getSensors,
                required this.activeMaskNotifier
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<int?>(
                        valueListenable: activeMaskNotifier,
                        builder: (context, mask, _) {
                                return SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                                children: [
                                                        ...createAllSensorGroups(
                                                                maskNotifier: activeMaskNotifier,
                                                                getSensors: getSensors,
                                                                onTap: (context, sensor) => showPopup(context, sensor),
                                                                configMode: false,
                                                                showInactive: false,
                                                                testMode: false
                                                        )
                                                ]
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
                        transitionBuilder: (_, anim, __, ___) => Transform.scale(
                                scale: anim.value,
                                alignment: Alignment.center,
                                child: Opacity(
                                        opacity: anim.value,
                                        child: SensorPopup(sensor: sensor)
                                )
                        )
                );
        }
}