import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_button.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';
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
        bool authenticated = false;

        late int initialMask;
        late TextEditingController sleepController, seaController, captureController;

        late ValueNotifier<int> localMaskNotifier;
        late ValueNotifier<int> iridiumModeNotifier;

        int initSleepTime = 0, sleepTime = 0;
        double initSeaPressure = 0, seaPressure = 0;
        int initCaptureAmount = 0, captureAmount = 0;
        int initIridiumMode = 0, iridiumMode = 0;
        bool invalidSleepTime = false, invalidCaptureAmount = false;

        @override
        void initState() {
                super.initState();
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier(initialMask);
                iridiumModeNotifier = ValueNotifier(0);

                sleepController = TextEditingController();
                seaController = TextEditingController();
                captureController = TextEditingController();

                widget.configNotifier.addListener(reload);
                reload();
                WidgetsBinding.instance.addPostFrameCallback((_) => askPassword());
        }

        void reload() {
                final raw = widget.configNotifier.value;
                if (raw == null) return;
                final params = parseSeriesParams(raw);
                setState(() {
                                initSleepTime = params.sleepTime;
                                sleepTime = params.sleepTime;
                                sleepController.text = params.sleepTime.toString();
                                initSeaPressure = params.seaPressure;
                                seaPressure = params.seaPressure;
                                seaController.text = params.seaPressure.toString();
                                initCaptureAmount = params.capture;
                                captureAmount = params.capture;
                                captureController.text = params.capture.toString();
                                initIridiumMode = params.iridiumMode;
                                iridiumMode = params.iridiumMode; 
                                iridiumModeNotifier.value = params.iridiumMode;
                        }
                );
        }

        // La place où on demande le mot de passe pour accéder à la config
        Future<void> askPassword() async {
                final ok = await showPasswordDialog(context, motDePasse: '');
                if (!ok) widget.onCancel(); else setState(() => authenticated = true);
        }

        @override
        void dispose() {
                widget.configNotifier.removeListener(reload);
                localMaskNotifier.dispose();
                sleepController.dispose();
                seaController.dispose();
                captureController.dispose();
                iridiumModeNotifier.dispose();
                super.dispose();
        }

        bool get maskChanged => localMaskNotifier.value != initialMask;
        bool get seriesChanged => (sleepTime != initSleepTime && !invalidSleepTime) ||
                (seaPressure != initSeaPressure) ||
                (captureAmount != initCaptureAmount && !invalidCaptureAmount) ||
                (iridiumMode != initIridiumMode);

        Future<bool> confirmDiscard() async {
                if (maskChanged || seriesChanged) return showDiscardDialog(context);
                return true;
        }

        @override
        Widget build(BuildContext context) {
                if (!authenticated) return const SizedBox.shrink();
                return WillPopScope(
                        onWillPop: confirmDiscard,
                        child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                        children: [
                                                ...createAllSensorGroups(
                                                        maskNotifier: localMaskNotifier,
                                                        getSensors: getSensors,
                                                        onTap: (_, __) {
                                                        },
                                                        configMode: true,
                                                        testMode: false,
                                                        localMask: localMaskNotifier
                                                ),

                                                const SizedBox(height: 16),

                                                // Appliquer masque
                                                ConfigButton(
                                                        skipConfirmation: true,
                                                        action: () => sendMaskConfig(
                                                                context: context,
                                                                initialMask: initialMask,
                                                                newMask: localMaskNotifier.value,
                                                                messageService: widget.messageService
                                                        ).then(
                                                                        (ok) {
                                                                                if (ok) {
                                                                                        // Met à jour la valeur partagée
                                                                                        widget.activeMaskNotifier.value = localMaskNotifier.value;
                                                                                        // Réinitialise initialMask pour désactiver le bouton
                                                                                        setState(() => initialMask = localMaskNotifier.value);
                                                                                }
                                                                                return ok;
                                                                        }
                                                                ),
                                                        idleLabel: tr('config.apply'),
                                                        loadingLabel: '…',
                                                        successLabel: tr("config.success"),
                                                        failureLabel: tr('config.error'),
                                                        idleIcon: Icons.send,
                                                        successIcon: Icons.check,
                                                        failureIcon: Icons.error,
                                                        idleColor: Theme.of(context).primaryColor,
                                                        successColor: Colors.green,
                                                        failureColor: Colors.red,
                                                        enabled: maskChanged
                                                ),

                                                const SizedBox(height: 24),

                                                Center(child: Text(tr('config.collection_settings'), style: Theme.of(context).textTheme.titleMedium)),

                                                const SizedBox(height: 8),

                                                Card(
                                                        elevation: 2,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(16),
                                                                child: Column(
                                                                        children: [
                                                                                TextFormField(
                                                                                        controller: sleepController,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.sleep_minutes'),
                                                                                                labelStyle: TextStyle(color: invalidSleepTime ? Colors.red : null, fontWeight: FontWeight.bold)
                                                                                        ),
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (value) {
                                                                                                final x = validateSleep(int.tryParse(value) ?? 0);
                                                                                                invalidSleepTime = isSleepInvalid(int.tryParse(value) ?? 0);
                                                                                                setState(() => sleepTime = x.toInt());
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                TextFormField(
                                                                                        controller: seaController,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.sea_level_pressure')
                                                                                        ),
                                                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                                        onChanged: (value) => setState(() => seaPressure = double.tryParse(value) ?? seaPressure)
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                TextFormField(
                                                                                        controller: captureController,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.number_of_captures'),
                                                                                                labelStyle: TextStyle(color: invalidCaptureAmount ? Colors.red : null, fontWeight: FontWeight.bold)
                                                                                        ),
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (value) {
                                                                                                final x = validateCapture(int.tryParse(value) ?? 0);
                                                                                                invalidCaptureAmount = isCaptureInvalid(int.tryParse(value) ?? 0);
                                                                                                setState(() => captureAmount = x);
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                Card(
                                                                                        color: Colors.grey[700],
                                                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                                        child: Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                        Padding(
                                                                                                                padding: const EdgeInsets.all(8.0),
                                                                                                                child: Text(
                                                                                                                        tr('config.iridium_mode'),
                                                                                                                        style: const TextStyle(fontWeight: FontWeight.bold)
                                                                                                                )
                                                                                                        ),
                                                                                                        RadioListTile<int>(
                                                                                                                value: 0,
                                                                                                                groupValue: iridiumMode,
                                                                                                                onChanged: (value) => setState(() => iridiumMode = value ?? 0),
                                                                                                                title: Text(tr('config.iridium_none'))
                                                                                                        ),
                                                                                                        RadioListTile<int>(
                                                                                                                value: 1,
                                                                                                                groupValue: iridiumMode,
                                                                                                                onChanged: (value) => setState(() => iridiumMode = value ?? 0),
                                                                                                                title: Text(tr('config.iridium_netav')),
                                                                                                                subtitle: Text(tr('config.iridium_netav2'))
                                                                                                        ),
                                                                                                        RadioListTile<int>(
                                                                                                                value: 2,
                                                                                                                groupValue: iridiumMode,
                                                                                                                onChanged: (value) => setState(() => iridiumMode = value ?? 0),
                                                                                                                title: Text(tr('config.iridium_quality')),
                                                                                                                subtitle: Text(tr('config.iridium_quality2'))
                                                                                                        )
                                                                                                ]
                                                                                        )
                                                                                )
                                                                        ]
                                                                )
                                                        )
                                                ),

                                                const SizedBox(height: 8),

                                                Row(
                                                        children: [
                                                                // Bouton “Envoyer les paramètres”
                                                                Expanded(
                                                                        flex: 1,
                                                                        child: ConfigButton(
                                                                                action: () => sendSeriesConfig(
                                                                                        messageService: widget.messageService,
                                                                                        sleep: sleepTime,
                                                                                        initSleep: initSleepTime,
                                                                                        updateInitSleep: (value) => initSleepTime = value,
                                                                                        seaPressure: seaPressure,
                                                                                        initSeaPressure: initSeaPressure,
                                                                                        updateInitSeaPressure: (value) => initSeaPressure = value,
                                                                                        captureAmount: captureAmount,
                                                                                        initCaptureAmount: initCaptureAmount,
                                                                                        updateInitCaptureAmount: (value) => initCaptureAmount = value,
                                                                                        iridiumMode: iridiumMode,
                                                                                        initIridiumMode: initIridiumMode,
                                                                                        updateInitIridiumMode: (value) => initIridiumMode = value
                                                                                ),
                                                                                confirmTitle: tr('config.confirm_send'),
                                                                                confirmContent: tr('config.new_parameters_send'),
                                                                                idleLabel: tr('config.send'),
                                                                                loadingLabel: tr('config.sending'),
                                                                                successLabel: tr('config.success'),
                                                                                failureLabel: tr('config.error'),
                                                                                idleIcon: Icons.send,
                                                                                successIcon: Icons.check_circle,
                                                                                failureIcon: Icons.error,
                                                                                idleColor: Theme.of(context).primaryColor,
                                                                                successColor: Colors.green,
                                                                                failureColor: Colors.red,
                                                                                enabled: seriesChanged && !invalidSleepTime && !invalidCaptureAmount
                                                                        )
                                                                ),

                                                                const SizedBox(width: 8),

                                                                // Bouton “Reset default”
                                                                Expanded(
                                                                        flex: 1,
                                                                        child: ConfigButton(
                                                                                action: () => resetToDefaults(widget.messageService),
                                                                                confirmTitle: tr('config.confirm_reset'),
                                                                                confirmContent: tr('config.reset_default_title'),
                                                                                idleLabel: tr('config.reset_default'),
                                                                                loadingLabel: '…',
                                                                                successLabel: tr('config.success'),
                                                                                failureLabel: tr('config.error'),
                                                                                idleIcon: Icons.refresh,
                                                                                successIcon: Icons.check_circle,
                                                                                failureIcon: Icons.error,
                                                                                idleColor: Colors.red,
                                                                                successColor: Colors.green,
                                                                                failureColor: Colors.red,
                                                                                enabled: true
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