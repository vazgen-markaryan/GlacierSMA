import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
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
        late int initialMask;
        late ValueNotifier<int> localMaskNotifier;
        bool authenticated = false;

        late TextEditingController sleepCtrl, seaCtrl, captureCtrl;
        double initSleep = 0, sleep = 0;
        double initSea = 0, sea = 0;
        int initCapture = 0, cap = 0;
        bool invalidSleep = false, invalidCap = false;

        @override
        void initState() {
                super.initState();
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier(initialMask);

                sleepCtrl = TextEditingController();
                seaCtrl = TextEditingController();
                captureCtrl = TextEditingController();

                widget.configNotifier.addListener(reload);
                reload();
                WidgetsBinding.instance.addPostFrameCallback((_) => askPass());
        }

        void reload() {
                final raw = widget.configNotifier.value;
                if (raw == null) return;
                final p = parseSeriesParams(raw);
                setState(() {
                                initSleep = p.sleep;  sleep = p.sleep;   sleepCtrl.text = p.sleep.toInt().toString();
                                initSea = p.seaPressure; sea = p.seaPressure; seaCtrl.text = p.seaPressure.toString();
                                initCapture = p.capture;    cap = p.capture; captureCtrl.text = p.capture.toString();
                        }
                );
        }

        Future<void> askPass() async {
                final ok = await showPasswordDialog(context, motDePasse: '');
                if (!ok) widget.onCancel(); else setState(() => authenticated = true);
        }

        @override
        void dispose() {
                widget.configNotifier.removeListener(reload);
                localMaskNotifier.dispose();
                sleepCtrl.dispose(); seaCtrl.dispose(); captureCtrl.dispose();
                super.dispose();
        }

        bool get maskChanged => localMaskNotifier.value != initialMask;
        bool get seriesChanged => (sleep != initSleep && !invalidSleep) || (sea != initSea) || (cap != initCapture && !invalidCap);

        Future<bool> confirmDiscard() async {
                if (maskChanged || seriesChanged) return showDiscardDialog(context);
                return true;
        }

        @override
        Widget build(BuildContext ctx) {
                if (!authenticated) return const SizedBox.shrink();
                return WillPopScope(
                        onWillPop: confirmDiscard,
                        child: SingleChildScrollView(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Column(children: [

                                                ...createAllSensorGroups(
                                                        maskNotifier: localMaskNotifier,
                                                        getSensors: getSensors,
                                                        onTap: (_, __) {
                                                        },
                                                        configMode: true,
                                                        localMask: localMaskNotifier
                                                ),

                                                const SizedBox(height: defaultPadding),

                                                // Appliquer masque
                                                ConfigButton(
                                                        skipConfirmation: true,
                                                        action: () => sendMaskConfig(
                                                                context: ctx,
                                                                initialMask: initialMask,
                                                                newMask: localMaskNotifier.value,
                                                                svc: widget.messageService
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
                                                        idleColor: Theme.of(ctx).primaryColor,
                                                        successColor: Colors.green,
                                                        failureColor: Colors.red,
                                                        enabled: maskChanged
                                                ),

                                                const SizedBox(height: defaultPadding * 1.5),

                                                Center(child: Text(tr('config.collection_settings'), style: Theme.of(ctx).textTheme.titleMedium)),

                                                const SizedBox(height: defaultPadding / 2),

                                                Card(
                                                        elevation: 2,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(defaultPadding),
                                                                child: Column(
                                                                        children: [
                                                                                TextFormField(
                                                                                        controller: sleepCtrl,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.sleep_minutes'),
                                                                                                labelStyle: TextStyle(color: invalidSleep ? Colors.red : null, fontWeight: FontWeight.bold)
                                                                                        ),
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (v) {
                                                                                                final x = validateSleep(int.tryParse(v) ?? 0);
                                                                                                invalidSleep = isSleepInvalid(int.tryParse(v) ?? 0);
                                                                                                setState(() => sleep = x.toDouble());
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: defaultPadding / 2),

                                                                                TextFormField(
                                                                                        controller: seaCtrl,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.sea_level_pressure')
                                                                                        ),
                                                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                                                        onChanged: (v) => setState(() => sea = double.tryParse(v) ?? sea)
                                                                                ),

                                                                                const SizedBox(height: defaultPadding / 2),

                                                                                TextFormField(
                                                                                        controller: captureCtrl,
                                                                                        decoration: InputDecoration(
                                                                                                labelText: tr('config.number_of_captures'),
                                                                                                labelStyle: TextStyle(color: invalidCap ? Colors.red : null, fontWeight: FontWeight.bold)
                                                                                        ),
                                                                                        keyboardType: TextInputType.number,
                                                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                                                        onChanged: (v) {
                                                                                                final x = validateCapture(int.tryParse(v) ?? 0);
                                                                                                invalidCap = isCaptureInvalid(int.tryParse(v) ?? 0);
                                                                                                setState(() => cap = x);
                                                                                        }
                                                                                )
                                                                        ]
                                                                )
                                                        )
                                                ),

                                                const SizedBox(height: defaultPadding),

                                                Row(
                                                        children: [
                                                                // Bouton “Envoyer les paramètres”
                                                                Expanded(
                                                                        flex: 2,
                                                                        child: ConfigButton(
                                                                                action: () => sendSeriesConfig(
                                                                                        svc: widget.messageService,
                                                                                        sleep: sleep,
                                                                                        initSleep: initSleep,
                                                                                        updateInitSleep: (v) => initSleep = v,
                                                                                        sea: sea,
                                                                                        initSea: initSea,
                                                                                        updateInitSea: (v) => initSea = v,
                                                                                        capture: cap,
                                                                                        initCapture: initCapture,
                                                                                        updateInitCapture: (v) => initCapture = v
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
                                                                                enabled: seriesChanged && !invalidSleep && !invalidCap
                                                                        )
                                                                ),

                                                                const SizedBox(width: defaultPadding / 2),

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