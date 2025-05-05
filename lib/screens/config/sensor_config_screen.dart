import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_button.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';

/// Écran “Configuration des capteurs”
/// Utilise une copie **locale** du mask pour ne charger la config initiale qu'une seule fois,
/// et ne met à jour le mask global **qu’après** l’envoi.
class SensorConfigScreen extends StatefulWidget {
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;

        const SensorConfigScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.messageService
        }) : super(key: key);

        @override
        SensorConfigScreenState createState() => SensorConfigScreenState();
}

class SensorConfigScreenState extends State<SensorConfigScreen> {
        /// Valeur modifiable en local lors des toggles,
        /// pour que l’utilisateur puisse changer plusieurs switches avant d’appliquer.
        late final ValueNotifier<int> localMaskNotifier;

        @override
        void initState() {
                super.initState();
                // On initialise la copie locale avec la valeur actuelle du mask global
                localMaskNotifier = ValueNotifier<int>(widget.activeMaskNotifier.value ?? 0);
        }

        @override
        void dispose() {
                localMaskNotifier.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                // Préparation de la liste des capteurs configurables, triée par bitIndex
                final cfgSensors = allSensors
                        .where((s) => s.bitIndex != null)
                        .toList()
                ..sort((a, b) => a.bitIndex!.compareTo(b.bitIndex!));

                return ValueListenableBuilder<int>(
                        // Écoute le mask local pour rebuild seulement quand il change
                        valueListenable: localMaskNotifier,
                        builder: (ctx, m, _) {
                                // Séparation Internes / ModBus
                                final internals = cfgSensors.where((s) => s.bus?.toLowerCase() == 'i2c').toList();
                                final modbus = cfgSensors.where((s) => s.bus?.toLowerCase() == 'modbus').toList();

                                return SingleChildScrollView(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                children: [
                                                        // --- Liste des capteurs internes à configurer ---
                                                        SensorsGroup(
                                                                title: 'CAPTEURS INTERNES',
                                                                sensors: internals,
                                                                emptyMessage: 'Aucun capteur interne à configurer.',
                                                                itemBuilder: (ctx, s) {
                                                                        final bit = s.bitIndex!;
                                                                        return SensorCard(
                                                                                sensor: s,
                                                                                configMode: true,
                                                                                // Affichage du switch on/off basé sur le mask local
                                                                                isOn: (m & (1 << bit)) != 0,
                                                                                onToggle: (v) {
                                                                                        // Mise à jour du mask local dès que l’utilisateur togg le switch
                                                                                        final newMask = v ? (m | (1 << bit)) : (m & ~(1 << bit));
                                                                                        localMaskNotifier.value = newMask;
                                                                                }
                                                                        );
                                                                }
                                                        ),

                                                        const SizedBox(height: defaultPadding * 2),

                                                        // --- Liste des capteurs ModBus à configurer ---
                                                        SensorsGroup(
                                                                title: 'CAPTEURS MODBUS',
                                                                sensors: modbus,
                                                                emptyMessage: 'Aucun capteur ModBus à configurer.',
                                                                itemBuilder: (ctx, s) {
                                                                        final bit = s.bitIndex!;
                                                                        return SensorCard(
                                                                                sensor: s,
                                                                                configMode: true,
                                                                                isOn: (m & (1 << bit)) != 0,
                                                                                onToggle: (v) {
                                                                                        final newMask = v ? (m | (1 << bit)) : (m & ~(1 << bit));
                                                                                        localMaskNotifier.value = newMask;
                                                                                }
                                                                        );
                                                                }
                                                        ),

                                                        const SizedBox(height: defaultPadding * 2),

                                                        // --- Bouton Appliquer la configuration ---
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                                                                child: ConfigButton(
                                                                        idleLabel: 'Appliquer la configuration',
                                                                        successLabel: 'Configuration Enregistré',
                                                                        failureLabel: 'Erreur de l\'Enregistrement',
                                                                        onSubmit: () async {
                                                                                // 1) Affiche un popup bloquant pour empêcher la navigation
                                                                                //    - barrierDismissible: false empêche de le fermer par un tap hors popup
                                                                                showDialog(
                                                                                        context: context,
                                                                                        barrierDismissible: false,
                                                                                        builder: (_) => const CustomPopup(
                                                                                                title: 'Application en cours',
                                                                                                content: Padding(
                                                                                                        padding: EdgeInsets.symmetric(vertical: 20),
                                                                                                        child: CircularProgressIndicator()
                                                                                                ),
                                                                                                actions: []  // Pas de bouton de fermeture manuel
                                                                                        )
                                                                                );

                                                                                // 2) Envoi de la nouvelle configuration au firmware, basé sur le mask local
                                                                                final ok = await widget.messageService.sendSensorConfig(
                                                                                        List<bool>.generate(16, (i) => (localMaskNotifier.value & (1 << i)) != 0)
                                                                                );

                                                                                // 3) Si l’envoi réussit, on met à jour le mask global pour propager immédiatement
                                                                                if (ok) {
                                                                                        widget.activeMaskNotifier.value = localMaskNotifier.value;
                                                                                }

                                                                                // 4) Délai volontaire de 2 secondes :
                                                                                //    - Permet à l’utilisateur de voir le feedback « Succès » ou « Échec »
                                                                                //    - Laisse le temps aux éventuelles mises à jour des capteurs d’arriver
                                                                                await Future.delayed(const Duration(seconds: 2));

                                                                                // 5) Fermeture automatique du popup
                                                                                Navigator.of(context, rootNavigator: true).pop();

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