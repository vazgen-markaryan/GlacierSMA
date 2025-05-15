import '../../utils/custom_popup.dart';
import 'config_utils.dart';
import 'config_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// ConfigScreen : permet de configurer le masque de capteurs et les paramètres série (sommeil, pression, captures)
/// - Authentification utilisateur
/// - Basculer capteurs actifs/inactifs
/// - Appliquer le masque
/// - Afficher/modifier minutes de sommeil, pression mer, nombre captures
/// - Envoi unique vers le firmware via bouton “Envoyer les Paramètres”
class ConfigScreen extends StatefulWidget {
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;
        final VoidCallback onCancel;
        final ValueNotifier<RawData?> configNotifier;

        const ConfigScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.messageService,
                required this.onCancel,
                required this.configNotifier
        }) : super(key: key);

        @override
        ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
        late int initialMask;
        late ValueNotifier<int> localMaskNotifier;
        bool authenticated = false;

        double initSleep = 0;
        double sleepMinutes = 0;
        bool sleepInvalid = false;

        double initSea = 0;
        double seaPressure = 0;

        int initCapture = 0;
        int captureAmount = 0;
        bool captureInvalid = false;

        @override
        void initState() {
                super.initState();
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier(initialMask);
                widget.configNotifier.addListener(loadInitialConfig);
                loadInitialConfig();
                WidgetsBinding.instance.addPostFrameCallback((_) => askPassword());
        }

        void loadInitialConfig() {
                final raw = widget.configNotifier.value;
                if (raw == null) return;
                final map = raw.asMap;
                setState(
                        () {
                                initSleep = double.tryParse(map['sleep_minutes'] ?? '') ?? initSleep;
                                sleepMinutes = initSleep;
                                sleepInvalid = false;

                                initSea = double.tryParse(map['sea_level_pressure'] ?? '') ?? initSea;
                                seaPressure = initSea;

                                initCapture = int.tryParse(map['capture_amount'] ?? '') ?? initCapture;
                                captureAmount = initCapture;
                                captureInvalid = false;
                        }
                );
        }

        Future<void> askPassword() async {
                final ok = await showPasswordDialog(context, motDePasse: '');
                if (!ok) {
                        widget.onCancel();
                }
                else {
                        setState(() => authenticated = true);
                }
        }

        @override
        void dispose() {
                widget.configNotifier.removeListener(loadInitialConfig);
                localMaskNotifier.dispose();
                super.dispose();
        }

        bool get hasMaskChanged => localMaskNotifier.value != initialMask;

        bool get hasConfigChanged {
                final sleepChanged = sleepMinutes != initSleep && !sleepInvalid;
                final seaChanged = seaPressure != initSea;
                final capChanged = captureAmount != initCapture && !captureInvalid;
                return sleepChanged || seaChanged || capChanged;
        }

        /// Confirme l'abandon si des changements sont présents
        Future<bool> confirmDiscard() async {
                if (hasMaskChanged || hasConfigChanged) {
                        return showDiscardDialog(context);
                }
                return true;
        }

        Future<void> sendConfigs() async {
                final tasks = <Future<bool>>[];
                if (sleepMinutes != initSleep && !sleepInvalid) {
                        tasks.add(widget.messageService.sendConfigDouble('S', sleepMinutes));
                }
                if (seaPressure != initSea) {
                        tasks.add(widget.messageService.sendConfigDouble('P', seaPressure));
                }
                if (captureAmount != initCapture && !captureInvalid) {
                        tasks.add(widget.messageService.sendConfigInteger('C', captureAmount));
                }
                for (final task in tasks) await task;

                showCustomSnackBar(
                        context,
                        message: 'Envoi des Paramètres réussi',
                        iconData: Icons.check_circle,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        iconColor: Colors.white
                );
        }

        @override
        Widget build(BuildContext context) {
                if (!authenticated) return const SizedBox.shrink();

                return WillPopScope(
                        onWillPop: confirmDiscard,
                        child: SingleChildScrollView(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                                // Groupes de capteurs
                                                ...createAllSensorGroups(
                                                        maskNotifier: localMaskNotifier,
                                                        getSensors: getSensors,
                                                        onTap: (_, __) {
                                                        },
                                                        configMode: true,
                                                        localMask: localMaskNotifier
                                                ),
                                                const SizedBox(height: defaultPadding),

                                                // Bouton Appliquer le masque
                                                ConfigButton(
                                                        localMaskNotifier: localMaskNotifier,
                                                        initialMask: initialMask,
                                                        activeMaskNotifier: widget.activeMaskNotifier,
                                                        messageService: widget.messageService,
                                                        isEnabled: hasMaskChanged,
                                                        onSuccess: () => setState(() => initialMask = localMaskNotifier.value)
                                                ),

                                                const SizedBox(height: defaultPadding * 1.5),

                                                // Titre de la config série
                                                Center(
                                                        child: Text(
                                                                'Paramètres de la Station',
                                                                textAlign: TextAlign.center,
                                                                style: Theme.of(context).textTheme.titleMedium
                                                        )
                                                ),

                                                const SizedBox(height: defaultPadding / 2),

                                                // Carte des paramètres série
                                                Card(
                                                        elevation: 2,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(defaultPadding),
                                                                child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                        children: [
                                                                                TextFormField(
                                                                                        initialValue: sleepMinutes.toInt().toString(),
                                                                                        decoration: InputDecoration(
                                                                                                labelText: 'Minutes de Sleep (0–1440)',
                                                                                                labelStyle: TextStyle(
                                                                                                        color: sleepInvalid ? Colors.red : null,
                                                                                                        fontWeight: FontWeight.bold
                                                                                                )
                                                                                        ),
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (v) {
                                                                                                var x = int.tryParse(v) ?? 0;
                                                                                                if (x < 0) x = 0;
                                                                                                sleepInvalid = x > 1440;
                                                                                                setState(() => sleepMinutes = x.toDouble());
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: defaultPadding / 2),

                                                                                TextFormField(
                                                                                        initialValue: seaPressure.toString(),
                                                                                        decoration: const InputDecoration(
                                                                                                labelText: 'Pression de la Mer (hectoPascal)'
                                                                                        ),
                                                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                                        onChanged: (v) => setState(() => seaPressure = double.tryParse(v) ?? seaPressure)
                                                                                ),

                                                                                const SizedBox(height: defaultPadding / 2),

                                                                                TextFormField(
                                                                                        initialValue: captureAmount.toString(),
                                                                                        decoration: InputDecoration(
                                                                                                labelText: 'Nombre de Captures (0–255)',
                                                                                                labelStyle: TextStyle(
                                                                                                        color: captureInvalid ? Colors.red : null,
                                                                                                        fontWeight: FontWeight.bold
                                                                                                )
                                                                                        ),
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (v) {
                                                                                                var x = int.tryParse(v) ?? 0;
                                                                                                if (x < 0) x = 0;
                                                                                                captureInvalid = x > 255;
                                                                                                x = x.clamp(0, 255);
                                                                                                setState(() => captureAmount = x);
                                                                                        }
                                                                                )
                                                                        ]
                                                                )
                                                        )
                                                ),

                                                const SizedBox(height: defaultPadding),

                                                // Boutons Envoyer et Réinitialiser par défaut
                                                Row(
                                                        children: [
                                                                // Envoi des paramètres (66%)
                                                                Expanded(
                                                                        flex: 2,
                                                                        child: SizedBox(
                                                                                height: 48,
                                                                                child: ElevatedButton.icon(
                                                                                        onPressed: hasConfigChanged && !sleepInvalid && !captureInvalid
                                                                                                ? sendConfigs
                                                                                                : null,
                                                                                        icon: const Icon(Icons.send, color: Colors.white),
                                                                                        label: const Text('Envoyer les Paramètres', style: TextStyle(color: Colors.white)),
                                                                                        style: ElevatedButton.styleFrom(
                                                                                                backgroundColor: Theme.of(context).primaryColor
                                                                                        )
                                                                                )
                                                                        )
                                                                ),

                                                                const SizedBox(width: defaultPadding / 2),

                                                                // Réinitialiser aux valeurs par défaut (33%)
                                                                Expanded(
                                                                        flex: 1,
                                                                        child: SizedBox(
                                                                                height: 48,
                                                                                child: ElevatedButton.icon(
                                                                                        onPressed: () async {

                                                                                                // Confirmation avant reset
                                                                                                final confirmed = await showDialog<bool>(
                                                                                                        context: context,
                                                                                                        barrierDismissible: false,
                                                                                                        builder: (ctx) => CustomPopup(
                                                                                                                title: 'Confirmer la réinitialisation',
                                                                                                                content: const Text('Voulez-vous restaurer les paramètres par défaut?'),
                                                                                                                actions: [
                                                                                                                        TextButton(
                                                                                                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                                                                                                child: const Text('Annuler')
                                                                                                                        ),
                                                                                                                        TextButton(
                                                                                                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                                                                                                child: const Text('Confirmer')
                                                                                                                        )
                                                                                                                ]
                                                                                                        )
                                                                                                );

                                                                                                if (confirmed == true) {
                                                                                                        // Envoie du reset au firmware
                                                                                                        final success = await widget.messageService.sendHeartbeat('<default-settings>');
                                                                                                        if (success == true) {
                                                                                                                showCustomSnackBar(
                                                                                                                        context,
                                                                                                                        message: 'Paramètres réinitialisés aux valeurs par défaut',
                                                                                                                        iconData: Icons.refresh,
                                                                                                                        backgroundColor: Colors.red,
                                                                                                                        textColor: Colors.white,
                                                                                                                        iconColor: Colors.white
                                                                                                                );
                                                                                                        }
                                                                                                        else {
                                                                                                                showCustomSnackBar(
                                                                                                                        context,
                                                                                                                        message: 'Échec de la réinitialisation des paramètres',
                                                                                                                        iconData: Icons.error,
                                                                                                                        backgroundColor: Colors.orange,
                                                                                                                        textColor: Colors.white,
                                                                                                                        iconColor: Colors.white
                                                                                                                );
                                                                                                        }
                                                                                                }
                                                                                        },
                                                                                        icon: const Icon(Icons.refresh, color: Colors.white),
                                                                                        label: const Text('Reset default', style: TextStyle(color: Colors.white)),
                                                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red)
                                                                                )
                                                                        )
                                                                )
                                                        ]
                                                )
                                        ]
                                )
                        )
                );
        }
}