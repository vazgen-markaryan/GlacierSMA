import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/message_service.dart';
import '../home/sensors/sensor_card.dart';
import '../home/sensors/sensors_data.dart';
import '../home/sensors/sensors_group.dart';
import 'config_button.dart';

/// Écran “Configuration des capteurs”
/// Tout est piloté par [activeMaskNotifier].
class SensorConfigScreen extends StatelessWidget {
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;

        const SensorConfigScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.messageService
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                // 1) Prépare la liste triée des capteurs à configurer
                final cfgSensors = allSensors
                        .where((s) => s.bitIndex != null)
                        .toList()
                ..sort((a, b) => a.bitIndex!.compareTo(b.bitIndex!));

                return ValueListenableBuilder<int?>(
                        valueListenable: activeMaskNotifier,
                        builder: (context, mask, _) {
                                final m = mask ?? 0;
                                // Sépare Internes / ModBus
                                final internals = cfgSensors.where((s) => s.bus?.toLowerCase() == 'i2c').toList();
                                final modbus = cfgSensors.where((s) => s.bus?.toLowerCase() == 'modbus').toList();

                                return SingleChildScrollView(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                children: [
                                                        // --- Internes ---
                                                        SensorsGroup(
                                                                title: 'CAPTEURS INTERNES',
                                                                sensors: internals,
                                                                emptyMessage: 'Aucun capteur interne à configurer.',
                                                                itemBuilder: (ctx, s) {
                                                                        final bit = s.bitIndex!;
                                                                        final on = (m & (1 << bit)) != 0;
                                                                        return SensorCard(
                                                                                sensor: s,
                                                                                configMode: true,
                                                                                isOn: on,
                                                                                onToggle: (v) {
                                                                                        final newMask = v ? (m | (1 << bit)) : (m & ~(1 << bit));
                                                                                        activeMaskNotifier.value = newMask;
                                                                                }
                                                                        );
                                                                }
                                                        ),

                                                        const SizedBox(height: defaultPadding * 2),

                                                        // --- ModBus ---
                                                        SensorsGroup(
                                                                title: 'CAPTEURS MODBUS',
                                                                sensors: modbus,
                                                                emptyMessage: 'Aucun capteur ModBus à configurer.',
                                                                itemBuilder: (ctx, s) {
                                                                        final bit = s.bitIndex!;
                                                                        final on = (m & (1 << bit)) != 0;
                                                                        return SensorCard(
                                                                                sensor: s,
                                                                                configMode: true,
                                                                                isOn: on,
                                                                                onToggle: (v) {
                                                                                        final newMask = v ? (m | (1 << bit)) : (m & ~(1 << bit));
                                                                                        activeMaskNotifier.value = newMask;
                                                                                }
                                                                        );
                                                                }
                                                        ),

                                                        const SizedBox(height: defaultPadding * 2),

                                                        // --- Bouton Appliquer ---
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                                                                child: ConfigButton(
                                                                        idleLabel: 'Appliquer la configuration',
                                                                        successLabel: 'Enregistré',
                                                                        failureLabel: 'Erreur',
                                                                        onSubmit: () async {
                                                                                // On lit directement le mask depuis le notifier
                                                                                final currentMask = activeMaskNotifier.value ?? 0;
                                                                                // Envoi au firmware
                                                                                final ok = await messageService.sendSensorConfig(
                                                                                        // transforme currentMask en List<bool>
                                                                                        List<bool>.generate(16, (i) => (currentMask & (1 << i)) != 0)
                                                                                );
                                                                                return ok;
                                                                        }
                                                                )
                                                        )
                                                ]
                                        )
                                );
                        }
                );
        }
}