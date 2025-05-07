import 'config_utils.dart';
import 'config_button.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Écran principal de configuration :
/// Gère l’authentification,
/// Affiche les capteurs configurables,
/// Propose le bouton “Appliquer” en bas.
class ConfigScreen extends StatefulWidget {
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;
        final VoidCallback onCancel;

        const ConfigScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.messageService,
                required this.onCancel
        }) : super(key: key);

        @override
        ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
        late int initialMask;
        late ValueNotifier<int> localMaskNotifier;
        bool authenticated = false;

        @override
        void initState() {
                super.initState();
                // Initialise les masques
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier(initialMask);

                // Demande le mot de passe après le premier build
                WidgetsBinding.instance.addPostFrameCallback((_) => askPassword());
        }

        /// Affiche le popup de mot de passe, ou annule l’écran si refus
        Future<void> askPassword() async {
                final ok = await showPasswordDialog(context, motDePasse: '');
                if (!ok) {
                        // Si l’utilisateur ferme ou refuse, on retourne à l’Accueil
                        widget.onCancel();
                }
                else {
                        setState(() => authenticated = true);
                }
        }

        /// Confirme l’abandon si des changements non sauvegardés subsistent
        Future<bool> confirmDiscard() async {
                if (localMaskNotifier.value == initialMask) return true;
                return showDiscardDialog(context);
        }

        @override
        void dispose() {
                localMaskNotifier.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                if (!authenticated) {
                        // Tant que l’utilisateur n’est pas authentifié, on n’affiche rien
                        return const SizedBox.shrink();
                }

                // Récupère la valeur courante du mask
                final m = localMaskNotifier.value;

                // Liste triée des capteurs configurables
                final cfgSensors = allSensors.where((s) => s.bitIndex != null).toList()..sort((a, b) => a.bitIndex!.compareTo(b.bitIndex!));

                // Séparation I2C vs ModBus
                final internals = cfgSensors.where((s) => s.bus?.toLowerCase() == 'i2c').toList();
                final modbus = cfgSensors.where((s) => s.bus?.toLowerCase() == 'modbus').toList();

                // Détecte si le mask local a changé
                final hasChanged = m != initialMask;

                return WillPopScope(
                        onWillPop: confirmDiscard,
                        child: SingleChildScrollView(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Column(
                                        children: [
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
                                                                                // Met à jour la copie locale du mask
                                                                                localMaskNotifier.value = v
                                                                                        ? (m | (1 << bit))
                                                                                        : (m & ~(1 << bit));
                                                                        }
                                                                );
                                                        }
                                                ),

                                                const SizedBox(height: defaultPadding * 2),

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
                                                                                localMaskNotifier.value = v
                                                                                        ? (m | (1 << bit))
                                                                                        : (m & ~(1 << bit));
                                                                        }
                                                                );
                                                        }
                                                ),

                                                const SizedBox(height: defaultPadding),

                                                // Bouton Appliquer
                                                ConfigButton(
                                                        localMaskNotifier: localMaskNotifier,
                                                        initialMask: initialMask,
                                                        activeMaskNotifier: widget.activeMaskNotifier,
                                                        messageService: widget.messageService,
                                                        isEnabled: hasChanged,
                                                        onSuccess: () {
                                                                // Après un succès, on réinitialise initialMask pour éviter le popup d’abandon
                                                                setState(() {
                                                                                initialMask = localMaskNotifier.value;
                                                                        }
                                                                );
                                                        }
                                                )
                                        ]
                                )
                        )
                );
        }
}