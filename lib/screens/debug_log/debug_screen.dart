import 'package:flutter/material.dart';
import 'components/debug_log_updater.dart';
import 'components/debug_log_processor.dart';
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
                                                padding: const EdgeInsets.all(defaultPadding),
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                DebugLogProcessor(debugLogManager: debugLogManager),

                                                                const SizedBox(height: defaultPadding * 2),

                                                                ...createAllSensorGroups(
                                                                        maskNotifier: activeMaskNotifier,
                                                                        getSensors: getSensors,
                                                                        onTap: (ctx, s) => showPopup(ctx, s),
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

        void showPopup(BuildContext ctx, SensorsData sensor) {
                showGeneralDialog(
                        context: ctx,
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