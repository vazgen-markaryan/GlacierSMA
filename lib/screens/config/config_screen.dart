// ****************************************************************************
// ConfigScreen :
// Interface pour configurer le masque et les paramètres série.
// Plus de variables privées, plus de méthodes préfixées par '_'.
// Ajout de spinners pendant l’envoi et la réinitialisation.
// ****************************************************************************

import '../../utils/custom_popup.dart';
import 'config_utils.dart';
import 'config_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

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
        // Capteur mask state
        late int initialMask;
        late ValueNotifier<int> localMaskNotifier;
        bool authenticated = false;

        // Series parameters state
        double initSleep = 0;
        double sleepMinutes = 0;
        bool sleepInvalid = false;
        late TextEditingController sleepController;

        double initSea = 0;
        double seaPressure = 0;
        late TextEditingController seaController;

        int initCapture = 0;
        int captureAmount = 0;
        bool captureInvalid = false;
        late TextEditingController captureController;

        // Loading flags
        bool applyingConfigs = false;
        bool resettingDefaults = false;

        @override
        void initState() {
                super.initState();
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier(initialMask);

                sleepController = TextEditingController();
                seaController = TextEditingController();
                captureController = TextEditingController();

                widget.configNotifier.addListener(loadInitialConfig);
                loadInitialConfig();

                WidgetsBinding.instance.addPostFrameCallback((_) => askPassword());
        }

        void loadInitialConfig() {
                final raw = widget.configNotifier.value;
                if (raw == null) return;
                final map = raw.asMap;
                setState(() {
                                initSleep = double.tryParse(map['sleep_minutes'] ?? '') ?? initSleep;
                                sleepMinutes = initSleep;
                                sleepInvalid = false;
                                sleepController.text = initSleep.toInt().toString();

                                initSea = double.tryParse(map['sea_level_pressure'] ?? '') ?? initSea;
                                seaPressure = initSea;
                                seaController.text = initSea.toString();

                                initCapture = int.tryParse(map['capture_amount'] ?? '') ?? initCapture;
                                captureAmount = initCapture;
                                captureInvalid = false;
                                captureController.text = initCapture.toString();
                        }
                );
        }

        Future<void> askPassword() async {
                final ok = await showPasswordDialog(context, motDePasse: '');
                if (!ok) widget.onCancel();
                else setState(() => authenticated = true);
        }

        @override
        void dispose() {
                widget.configNotifier.removeListener(loadInitialConfig);
                localMaskNotifier.dispose();
                sleepController.dispose();
                seaController.dispose();
                captureController.dispose();
                super.dispose();
        }

        bool get hasMaskChanged => localMaskNotifier.value != initialMask;
        bool get hasConfigChanged {
                final sleepChanged = sleepMinutes != initSleep && !sleepInvalid;
                final seaChanged = seaPressure != initSea;
                final capChanged = captureAmount != initCapture && !captureInvalid;
                return sleepChanged || seaChanged || capChanged;
        }

        Future<bool> confirmDiscard() async {
                if (hasMaskChanged || hasConfigChanged) {
                        return showDiscardDialog(context);
                }
                return true;
        }

        Future<void> sendConfigs() async {
                if (!hasConfigChanged) {
                        showCustomSnackBar(
                                context,
                                message: 'Aucun changement à envoyer',
                                iconData: Icons.error,
                                backgroundColor: Colors.orange,
                                textColor: Colors.white,
                                iconColor: Colors.white
                        );
                        return;
                }
                setState(() => applyingConfigs = true);
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
                bool allOk = true;
                for (final task in tasks) {
                        final ok = await task;
                        if (!ok) allOk = false;
                }
                setState(() => applyingConfigs = false);
                if (allOk) {
                        setState(() {
                                        initSleep = sleepMinutes;
                                        initSea = seaPressure;
                                        initCapture = captureAmount;
                                }
                        );
                }
                showCustomSnackBar(
                        context,
                        message: allOk
                                ? 'Envoi des configurations terminé avec succès'
                                : 'Erreur lors de l’envoi de certaines configurations',
                        iconData: allOk ? Icons.check_circle : Icons.error,
                        backgroundColor: allOk ? Colors.green : Colors.red,
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
                                                ...createAllSensorGroups(
                                                        maskNotifier: localMaskNotifier,
                                                        getSensors: getSensors,
                                                        onTap: (_, __) {
                                                        },
                                                        configMode: true,
                                                        localMask: localMaskNotifier
                                                ),
                                                const SizedBox(height: defaultPadding),
                                                ConfigButton(
                                                        localMaskNotifier: localMaskNotifier,
                                                        initialMask: initialMask,
                                                        activeMaskNotifier: widget.activeMaskNotifier,
                                                        messageService: widget.messageService,
                                                        isEnabled: hasMaskChanged,
                                                        onSuccess: () => setState(() => initialMask = localMaskNotifier.value)
                                                ),
                                                const SizedBox(height: defaultPadding * 1.5),
                                                Center(
                                                        child: Text(
                                                                'Paramètres Série',
                                                                textAlign: TextAlign.center,
                                                                style: Theme.of(context).textTheme.titleMedium
                                                        )
                                                ),
                                                const SizedBox(height: defaultPadding / 2),
                                                Card(
                                                        elevation: 2,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(defaultPadding),
                                                                child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                        children: [
                                                                                TextFormField(
                                                                                        controller: sleepController,
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
                                                                                        controller: seaController,
                                                                                        decoration: const InputDecoration(
                                                                                                labelText: 'Pression de la Mer (hPa)',
                                                                                                helperText: 'Float en hectopascal'
                                                                                        ),
                                                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                                        onChanged: (v) => setState(
                                                                                                () => seaPressure = double.tryParse(v) ?? seaPressure)
                                                                                ),
                                                                                const SizedBox(height: defaultPadding / 2),
                                                                                TextFormField(
                                                                                        controller: captureController,
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
                                                Row(
                                                        children: [
                                                                Expanded(
                                                                        flex: 2,
                                                                        child: SizedBox(
                                                                                height: 48,
                                                                                child: applyingConfigs
                                                                                        ? Center(child: CircularProgressIndicator())
                                                                                        : ElevatedButton.icon(
                                                                                                onPressed: hasConfigChanged && !sleepInvalid && !captureInvalid
                                                                                                        ? () async {
                                                                                                                final confirmed = await showDialog<bool>(
                                                                                                                        context: context,
                                                                                                                        barrierDismissible: false,
                                                                                                                        builder: (ctx) => CustomPopup(
                                                                                                                                title: 'Confirmer l\'envoi',
                                                                                                                                content: const Text('Voulez-vous envoyer les nouveaux paramètres ?'),
                                                                                                                                actions: [
                                                                                                                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                                                                                                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmer'))
                                                                                                                                ]
                                                                                                                        )
                                                                                                                );
                                                                                                                if (confirmed == true) {
                                                                                                                        await sendConfigs();
                                                                                                                }
                                                                                                        }
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
                                                                Expanded(
                                                                        flex: 1,
                                                                        child: SizedBox(
                                                                                height: 48,
                                                                                child: resettingDefaults
                                                                                        ? Center(child: CircularProgressIndicator())
                                                                                        : ElevatedButton.icon(
                                                                                                onPressed: () async {
                                                                                                        final confirmed = await showDialog<bool>(
                                                                                                                context: context,
                                                                                                                barrierDismissible: false,
                                                                                                                builder: (ctx) => CustomPopup(
                                                                                                                        title: 'Confirmer la réinitialisation',
                                                                                                                        content: const Text('Voulez-vous restaurer les paramètres par défaut ?'),
                                                                                                                        actions: [
                                                                                                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                                                                                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmer'))
                                                                                                                        ]
                                                                                                                )
                                                                                                        );
                                                                                                        if (confirmed == true) {
                                                                                                                setState(() => resettingDefaults = true);
                                                                                                                final oldRaw = widget.configNotifier.value;
                                                                                                                final success = await widget.messageService.sendHeartbeat('<default-settings>');
                                                                                                                setState(() => resettingDefaults = false);
                                                                                                                if (success) {
                                                                                                                        void snackListener() {
                                                                                                                                final newRaw = widget.configNotifier.value;
                                                                                                                                if (newRaw != oldRaw) {
                                                                                                                                        widget.configNotifier.removeListener(snackListener);
                                                                                                                                        showCustomSnackBar(
                                                                                                                                                context,
                                                                                                                                                message: 'Paramètres réinitialisés aux valeurs par défaut',
                                                                                                                                                iconData: Icons.check_circle,
                                                                                                                                                backgroundColor: Colors.green,
                                                                                                                                                textColor: Colors.white,
                                                                                                                                                iconColor: Colors.white
                                                                                                                                        );
                                                                                                                                }
                                                                                                                        }
                                                                                                                        widget.configNotifier.addListener(snackListener);
                                                                                                                }
                                                                                                                else {
                                                                                                                        showCustomSnackBar(
                                                                                                                                context,
                                                                                                                                message: 'Échec de la réinitialisation des paramètres',
                                                                                                                                iconData: Icons.error,
                                                                                                                                backgroundColor: Colors.red,
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