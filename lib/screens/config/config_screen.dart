import 'config_utils.dart';
import 'config_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Écran principal de configuration :
/// Gère l’authentification,
/// Affiche les capteurs configurables,
/// Propose le bouton “Appliquer” et le bouton “Envoyer” pour config série.
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
                setState(() {
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
                if (!ok) widget.onCancel();
                else setState(() => authenticated = true);
        }

        Future<bool> confirmDiscard() async {
                if (localMaskNotifier.value != initialMask) return showDiscardDialog(context);
                return true;
        }

        @override
        void dispose() {
                widget.configNotifier.removeListener(loadInitialConfig);
                localMaskNotifier.dispose();
                super.dispose();
        }

        bool get hasMaskChanged => localMaskNotifier.value != initialMask;
        bool get hasConfigChanged =>
        (sleepMinutes != initSleep && !sleepInvalid) ||
                (seaPressure != initSea) ||
                (captureAmount != initCapture && !captureInvalid);

        Future<void> sendConfigs() async {
                final tasks = <Future<bool>>[];
                if (sleepMinutes != initSleep && !sleepInvalid) {
                        tasks.add(widget.messageService.sendConfigFloat('S', sleepMinutes));
                }
                if (seaPressure != initSea) {
                        tasks.add(widget.messageService.sendConfigFloat('P', seaPressure));
                }
                if (captureAmount != initCapture && !captureInvalid) {
                        tasks.add(widget.messageService.sendConfigUint8('C', captureAmount));
                }
                for (final task in tasks) {
                        await task;
                }
                showCustomSnackBar(
                        context,
                        message: 'Envoi des configurations terminé',
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
                                                ConfigButton(
                                                        localMaskNotifier: localMaskNotifier,
                                                        initialMask: initialMask,
                                                        activeMaskNotifier: widget.activeMaskNotifier,
                                                        messageService: widget.messageService,
                                                        isEnabled: hasMaskChanged,
                                                        onSuccess: () => setState(() => initialMask = localMaskNotifier.value)
                                                ),
                                                const SizedBox(height: defaultPadding * 1.5),
                                                Text('Paramètres série', style: Theme.of(context).textTheme.titleMedium),
                                                const SizedBox(height: defaultPadding / 2),
                                                TextFormField(
                                                        initialValue: sleepMinutes.toInt().toString(),
                                                        decoration: InputDecoration(
                                                                labelText: 'Minutes de sleep (0-1440)',
                                                                labelStyle: TextStyle(
                                                                        color: sleepInvalid ? const Color.fromARGB(255, 255, 0, 0) : null,
                                                                        fontWeight: FontWeight.bold
                                                                )
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onChanged: (v) {
                                                                var val = int.tryParse(v) ?? 0;
                                                                if (val < 0) val = 0;
                                                                sleepInvalid = val > 1440;
                                                                setState(() => sleepMinutes = val.toDouble());
                                                        }
                                                ),
                                                const SizedBox(height: defaultPadding / 2),
                                                TextFormField(
                                                        initialValue: seaPressure.toString(),
                                                        decoration: const InputDecoration(
                                                                labelText: 'Pression mer (hPa)',
                                                                helperText: 'Valeur float en hectopascal'
                                                        ),
                                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                        onChanged: (v) => setState(() => seaPressure = double.tryParse(v) ?? seaPressure)
                                                ),
                                                const SizedBox(height: defaultPadding / 2),
                                                TextFormField(
                                                        initialValue: captureAmount.toString(),
                                                        decoration: InputDecoration(
                                                                labelText: 'Nombre captures (0-255)',
                                                                labelStyle: TextStyle(
                                                                        color: captureInvalid ? const Color.fromARGB(255, 255, 0, 0) : null,
                                                                        fontWeight: FontWeight.bold
                                                                )
                                                        ),
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        onChanged: (v) {
                                                                var val = int.tryParse(v) ?? 0;
                                                                if (val < 0) val = 0;
                                                                captureInvalid = val > 255;
                                                                val = val.clamp(0, 255);
                                                                setState(() => captureAmount = val);
                                                        }
                                                ),
                                                const SizedBox(height: defaultPadding),
                                                ElevatedButton(
                                                        onPressed: (hasConfigChanged && !sleepInvalid && !captureInvalid) ? sendConfigs : null,
                                                        child: const Text('Envoyer')
                                                )
                                        ]
                                )
                        )
                );
        }
}