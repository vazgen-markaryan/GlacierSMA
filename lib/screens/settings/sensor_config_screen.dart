import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';

class SensorDescriptor {
        final String code;
        final String label;
        const SensorDescriptor(this.code, this.label);
}

const List<SensorDescriptor?> sensorDescriptors = [
        SensorDescriptor('BME280', 'Thermo-Hygro-Baromètre interne'),    // bit 0
        null,                                                            // bit 1
        SensorDescriptor('LSM303', 'Accéléro-Magnétomètre interne'),     // bit 2
        SensorDescriptor('Wind', 'Anémomètre extérieur'),               // bit 3
        SensorDescriptor('WindDir', 'Girouette extérieure'),            // bit 4
        SensorDescriptor('Stev', 'Pont Stevenson'),                     // bit 5
        SensorDescriptor('ASL20', 'Capteur de pression externe'),       // bit 6
        SensorDescriptor('BME485', 'Thermo-Hygro-Baromètre RS-485'),      // bit 7
        SensorDescriptor('GPS', 'Récepteur GPS'),                       // bit 8
        null, null, null, null, null, null, null                        // bits 9–15 réservés
];

class SensorConfigScreen extends StatefulWidget {
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;

        const SensorConfigScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.messageService
        }) : super(key: key);

        @override
        State<SensorConfigScreen> createState() => _SensorConfigScreenState();
}

class _SensorConfigScreenState extends State<SensorConfigScreen> {
        late List<bool> _enabled;

        @override
        void initState() {
                super.initState();
                final mask = widget.activeMaskNotifier.value ?? 0;
                _enabled = List.generate(16, (i) => (mask & (1 << i)) != 0);
                widget.activeMaskNotifier.addListener(_updateFromNotifier);
        }

        void _updateFromNotifier() {
                final mask = widget.activeMaskNotifier.value ?? 0;
                setState(() {
                        _enabled = List.generate(16, (i) => (mask & (1 << i)) != 0);
                });
        }

        @override
        void dispose() {
                widget.activeMaskNotifier.removeListener(_updateFromNotifier);
                super.dispose();
        }

        String _sensorLabel(int i) {
                final desc = sensorDescriptors[i];
                if (desc == null) return 'Capteur #$i (réservé)';
                return '${desc.label} (${desc.code})';
        }

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        body: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                        children: [
                                                Expanded(
                                                        child: ListView.builder(
                                                                itemCount: sensorDescriptors.length,
                                                                itemBuilder: (_, i) {
                                                                        // Si le slot est réservé, on peut l’ignorer ou le griser
                                                                        if (sensorDescriptors[i] == null) {
                                                                                return const SizedBox.shrink();
                                                                        }
                                                                        return SwitchListTile(
                                                                                title: Text(_sensorLabel(i)),
                                                                                value: _enabled[i],
                                                                                onChanged: (v) => setState(() => _enabled[i] = v),
                                                                        );
                                                                },
                                                        ),
                                                ),
                                                ElevatedButton(
                                                        onPressed: () async {
                                                                final success = await widget.messageService.sendSensorConfig(_enabled);
                                                                showCustomSnackBar(
                                                                        context,
                                                                        message: success
                                                                            ? 'Configuration envoyée'
                                                                            : 'Échec de l’envoi',
                                                                        iconData: success ? Icons.check_circle : Icons.error,
                                                                        backgroundColor: success ? Colors.green : Colors.red,
                                                                        textColor: Colors.white,
                                                                        iconColor: Colors.white,
                                                                );
                                                        },
                                                        child: const Text('Appliquer'),
                                                )
                                        ],
                                ),
                        ),
                );
        }
}