import '../../utils/constants.dart';
import 'package:flutter/material.dart';
import '../home/sensors/sensor_card.dart';
import '../home/sensors/sensors_data.dart';
import '../home/sensors/sensors_group.dart';
import 'components/debug_log_updater.dart';
import 'components/debug_log_processor.dart';
import '../home/sensors/sensor_popup.dart';

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
                                final m = mask ?? 0;

                                // Tous les capteurs internes + ModBus
                                final all = [
                                        ...getSensors(SensorType.internal),
                                        ...getSensors(SensorType.modbus)
                                ];

                                // Inactifs : powerStatus==null OU bitIndex désactivé
                                final inactive = all.where((s) {
                                                final physOff = s.powerStatus == null;
                                                final cfgOff = s.bitIndex != null && (m & (1 << s.bitIndex!)) == 0;
                                                return physOff || cfgOff;
                                        }
                                ).toList();

                                // Séparation
                                final internals = inactive.where((s) => s.bus?.toLowerCase() == 'i2c').toList();
                                final modbus = inactive.where((s) => s.bus?.toLowerCase() == 'modbus').toList();

                                return Scaffold(
                                        backgroundColor: backgroundColor,
                                        body: SingleChildScrollView(
                                                padding: const EdgeInsets.all(defaultPadding),
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                DebugLogProcessor(debugLogManager: debugLogManager),
                                                                const SizedBox(height: defaultPadding * 2),

                                                                SensorsGroup(
                                                                        title: 'CAPTEURS INTERNES',
                                                                        sensors: internals,
                                                                        emptyMessage: 'Aucun capteur interne inactif.',
                                                                        itemBuilder: (ctx, s) => SensorCard(
                                                                                sensor: s,
                                                                                onTap: (s.data.isNotEmpty && s.title != 'SD Card')
                                                                                        ? () => showPopup(ctx, s)
                                                                                        : null
                                                                        )
                                                                ),

                                                                SensorsGroup(
                                                                        title: 'CAPTEURS MODBUS',
                                                                        sensors: modbus,
                                                                        emptyMessage: 'Aucun capteur ModBus inactif.',
                                                                        itemBuilder: (ctx, s) => SensorCard(
                                                                                sensor: s,
                                                                                onTap: (s.data.isNotEmpty && s.title != 'SD Card')
                                                                                        ? () => showPopup(ctx, s)
                                                                                        : null
                                                                        )
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