import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/battery/battery_indicator.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// En-tête du Dashboard : statut USB + nom + icône “éditer” + indicateur batterie.
/// Se reconstruit automatiquement quand [firmwareNotifier] émet une nouvelle donnée.
class DashboardHeader extends StatelessWidget {
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;
        final ValueNotifier<double?> batteryVoltageNotifier;
        final ValueNotifier<RawData?> firmwareNotifier;
        final VoidCallback onRename;

        const DashboardHeader({
                super.key,
                required this.isConnected,
                required this.connectedDevices,
                required this.batteryVoltageNotifier,
                required this.firmwareNotifier,
                required this.onRename
        });

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<RawData?>(
                        valueListenable: firmwareNotifier,
                        builder: (_, idData, __) {
                                // Choix du nom : priorité au "name" venant du bloc <id>, sinon productName USB, sinon “Non connecté”
                                String name;
                                if (isConnected) {
                                        if (idData != null && (idData.asMap['name']?.isNotEmpty ?? false)) {
                                                name = idData.asMap['name']!;
                                        }
                                        else if (connectedDevices.isNotEmpty) {
                                                name = connectedDevices.first.productName;
                                        }
                                        else {
                                                name = 'Appareil inconnu';
                                        }
                                }
                                else {
                                        name = 'Non connecté';
                                }

                                return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                                Expanded(
                                                        child: Row(
                                                                children: [
                                                                        Icon(
                                                                                isConnected ? Icons.usb : Icons.usb_off,
                                                                                color: isConnected ? Colors.green : Colors.red
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        Flexible(
                                                                                child: Text(
                                                                                        name,
                                                                                        style: const TextStyle(fontSize: 16),
                                                                                        overflow: TextOverflow.ellipsis
                                                                                )
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        GestureDetector(
                                                                                onTap: onRename,
                                                                                child: const Icon(
                                                                                        Icons.edit,
                                                                                        size: 25,
                                                                                        color: Colors.white70
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                ),

                                                // Indicateur de batterie
                                                BatteryIndicator(voltageNotifier: batteryVoltageNotifier)
                                        ]
                                );
                        }
                );
        }
}