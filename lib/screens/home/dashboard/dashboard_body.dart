import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_popup.dart';

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
                                final effectiveMask = mask ?? 0;

                                // Filtre : seuls les capteurs dont le bit est à 1 (ou sans bitIndex) sont affichés
                                List<SensorsData> filter(List<SensorsData> list) => list
                                        .where((s) => s.bitIndex == null || (effectiveMask & (1 << s.bitIndex!)) != 0)
                                        .toList();

                                final internals = filter(getSensors(SensorType.internal));
                                final modbus = filter(getSensors(SensorType.modbus));

                                return SingleChildScrollView(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                children: [
                                                        SensorsGroup(
                                                                title: 'CAPTEURS INTERNES',
                                                                sensors: internals,
                                                                itemBuilder: (ctx, s) => SensorCard(
                                                                        sensor: s,
                                                                        onTap: (s.data.isNotEmpty && s.title != 'SD Card')
                                                                                ? () => showPopup(ctx, s)
                                                                                : null
                                                                )
                                                        ),

                                                        const SizedBox(height: defaultPadding),

                                                        SensorsGroup(
                                                                title: 'CAPTEURS MODBUS',
                                                                sensors: modbus,
                                                                itemBuilder: (ctx, s) => SensorCard(
                                                                        sensor: s,
                                                                        onTap: (s.data.isNotEmpty && s.title != 'SD Card')
                                                                                ? () => showPopup(ctx, s)
                                                                                : null
                                                                )
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