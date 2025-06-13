import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/secrets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_state.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_button.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Écran complet de configuration de la station (masque capteurs + séries)
/// - Gère le bitmask des capteurs via `createAllSensorGroups`
/// - Gère les paramètres série (sleep, pression, captures, iridium)
/// - Gère la validation des changements et le reset
/// - Demande un mot de passe avant d'autoriser l'accès

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
        /// Mode read-only si on est en Bluetooth
        bool get isReadOnly => GlobalConnectionState.instance.currentMode == ConnectionMode.bluetooth;

        /// Variables de travail locales pour masque et séries
        late int initialMask;
        late ValueNotifier<int> localMaskNotifier;
        late ValueNotifier<int> iridiumModeNotifier;

        late TextEditingController sleepController, seaController, captureController;

        int initSleepTime = 0, sleepTime = 0;
        double initSeaPressure = 0, seaPressure = 0;
        int initCaptureAmount = 0, captureAmount = 0;
        int initIridiumMode = 0, iridiumMode = 0;
        bool invalidSleepTime = false, invalidCaptureAmount = false;

        /// Indique si l'accès à l'écran est authentifié
        bool authenticated = false;

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

                /// Lance la demande de mot de passe après l'affichage initial
                WidgetsBinding.instance.addPostFrameCallback((_) => askPassword());
        }

        /// Recharge les paramètres séries depuis le bloc RawData reçu
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

        /// Demande le mot de passe d'accès
        Future<void> askPassword() async {
                if (isReadOnly) {
                        // Si Bluetooth, on affiche simplement le popup spécial
                        final result = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => CustomPopup(
                                        title: tr("config.bluetooth_blocked_title"),
                                        content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                        Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                        Icon(Icons.psychology, size: 30, color: Colors.yellow),
                                                                        SizedBox(width: 8),
                                                                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                                                        Icon(Icons.tune, size: 30, color: Colors.orangeAccent),
                                                                        SizedBox(width: 8),
                                                                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                                                        Icon(Icons.bluetooth, size: 30, color: Colors.blue),
                                                                        SizedBox(width: 8),
                                                                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                                                        Icon(Icons.bluetooth_disabled, size: 30, color: Colors.red),
                                                                        SizedBox(width: 8),
                                                                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                                                        Icon(Icons.usb, size: 30, color: Colors.green)
                                                                ]
                                                        ),
                                                        SizedBox(height: 16),
                                                        Text(
                                                                tr("config.bluetooth_blocked_message"),
                                                                style: TextStyle(color: Colors.white, fontSize: 16),
                                                                textAlign: TextAlign.center
                                                        )
                                                ]
                                        ),
                                        actions: [
                                                TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: Text("OK", style: TextStyle(color: Colors.white))
                                                )
                                        ],
                                        showCloseButton: false
                                )
                        );

                        // Si OK cliqué => on autorise l'accès
                        if (result == true) setState(() => authenticated = true);
                        else widget.onCancel();
                }
                else {
                        // Sinon mode câble classique : mot de passe habituel
                        final ok = await showPasswordDialog(context, motDePasse: configPassword);

                        if (!ok) widget.onCancel();
                        else setState(() => authenticated = true);
                }
        }

        @override
        void dispose() {
                widget.configNotifier.removeListener(reload);
                localMaskNotifier.dispose();
                iridiumModeNotifier.dispose();
                sleepController.dispose();
                seaController.dispose();
                captureController.dispose();
                super.dispose();
        }

        /// Détection de modifications
        bool get maskChanged => localMaskNotifier.value != initialMask;
        bool get seriesChanged =>
        (sleepTime != initSleepTime && !invalidSleepTime) ||
                (seaPressure != initSeaPressure) ||
                (captureAmount != initCaptureAmount && !invalidCaptureAmount) ||
                (iridiumMode != initIridiumMode);

        /// Confirmation en quittant l'écran si des changements sont non sauvegardés
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

                                                /// Gestion des capteurs avec le masque (bitmask)
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

                                                /// Bouton d'application du masque
                                                ConfigButton(
                                                        skipConfirmation: true,
                                                        action: () => sendMaskConfig(
                                                                context: context,
                                                                initialMask: initialMask,
                                                                newMask: localMaskNotifier.value,
                                                                messageService: widget.messageService
                                                        ).then((ok) {
                                                                                if (ok) {
                                                                                        widget.activeMaskNotifier.value = localMaskNotifier.value;
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
                                                        enabled: !isReadOnly && maskChanged
                                                ),

                                                const SizedBox(height: 24),

                                                /// Paramètres séries
                                                Center(
                                                        child: Text(
                                                                tr('config.collection_settings'),
                                                                style: Theme.of(context).textTheme.titleMedium
                                                        )
                                                ),

                                                const SizedBox(height: 8),

                                                Card(
                                                        elevation: 2,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(16),
                                                                child: Column(
                                                                        children: [

                                                                                /// Input : Sleep time
                                                                                TextFormField(
                                                                                        controller: sleepController,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.sleep_minutes'),
                                                                                                labelStyle: TextStyle(color: invalidSleepTime ? Colors.red : null, fontWeight: FontWeight.bold)
                                                                                        ),
                                                                                        enabled: !isReadOnly,
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (value) {
                                                                                                final x = validateSleep(int.tryParse(value) ?? 0);
                                                                                                invalidSleepTime = isSleepInvalid(int.tryParse(value) ?? 0);
                                                                                                setState(() => sleepTime = x.toInt());
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                /// Input : Sea pressure
                                                                                TextFormField(
                                                                                        controller: seaController,
                                                                                        decoration: InputDecoration(labelText: tr('config.sea_level_pressure')),
                                                                                        enabled: !isReadOnly,
                                                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                                        onChanged: (value) => setState(() => seaPressure = double.tryParse(value) ?? seaPressure)
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                /// Input : Capture amount
                                                                                TextFormField(
                                                                                        controller: captureController,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.number_of_captures'),
                                                                                                labelStyle: TextStyle(color: invalidCaptureAmount ? Colors.red : null, fontWeight: FontWeight.bold)
                                                                                        ),
                                                                                        enabled: !isReadOnly,
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (value) {
                                                                                                final x = validateCapture(int.tryParse(value) ?? 0);
                                                                                                invalidCaptureAmount = isCaptureInvalid(int.tryParse(value) ?? 0);
                                                                                                setState(() => captureAmount = x);
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: 8),

                                                                                /// Sélection du mode Iridium
                                                                                Card(
                                                                                        color: Colors.grey[700],
                                                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                                        child: Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                        Padding(
                                                                                                                padding: const EdgeInsets.all(8.0),
                                                                                                                child: Text(tr('config.iridium_mode'), style: const TextStyle(fontWeight: FontWeight.bold))
                                                                                                        ),
                                                                                                        RadioListTile<int>(
                                                                                                                value: 0,
                                                                                                                groupValue: iridiumMode,
                                                                                                                onChanged: isReadOnly ? null : (value) => setState(() => iridiumMode = value ?? 0),
                                                                                                                title: Text(tr('config.iridium_none'))
                                                                                                        ),
                                                                                                        RadioListTile<int>(
                                                                                                                value: 1,
                                                                                                                groupValue: iridiumMode,
                                                                                                                onChanged: isReadOnly ? null : (value) => setState(() => iridiumMode = value ?? 0),
                                                                                                                title: Text(tr('config.iridium_netav')),
                                                                                                                subtitle: Text(tr('config.iridium_netav2'))
                                                                                                        ),
                                                                                                        RadioListTile<int>(
                                                                                                                value: 2,
                                                                                                                groupValue: iridiumMode,
                                                                                                                onChanged: isReadOnly ? null : (value) => setState(() => iridiumMode = value ?? 0),
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

                                                /// Boutons Eenvoyer + Reset
                                                Row(
                                                        children: [

                                                                /// Bouton envoyer
                                                                Expanded(
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
                                                                                enabled: !isReadOnly && seriesChanged && !invalidSleepTime && !invalidCaptureAmount
                                                                        )
                                                                ),

                                                                const SizedBox(width: 8),

                                                                /// Bouton reset
                                                                Expanded(
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
                                                                                enabled: !isReadOnly
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