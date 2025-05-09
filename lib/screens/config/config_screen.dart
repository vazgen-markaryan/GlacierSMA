import 'config_utils.dart';
import 'config_button.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';

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

                // Détecte si le mask local a changé
                final hasChanged = localMaskNotifier.value != initialMask;

                return WillPopScope(
                        onWillPop: confirmDiscard,
                        child: SingleChildScrollView(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Column(
                                        children: [
                                                ...createAllSensorGroups(
                                                        maskNotifier: localMaskNotifier,
                                                        getSensors: getSensors,
                                                        onTap: (_, __) {},  // Pas utilisé en configMode
                                                        configMode: true,
                                                        localMask: localMaskNotifier
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
