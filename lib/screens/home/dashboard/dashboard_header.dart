import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/battery/battery_indicator.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Widget pour l’en-tête du Dashboard : statut USB, nom de l’appareil et niveau de batterie.
/// Lit en priorité le champ “name” du bloc <id>, puis tombe sur productName USB.
class DashboardHeader extends StatelessWidget {
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;
        final ValueNotifier<double?> batteryVoltageNotifier;
        final ValueNotifier<RawData?> firmwareNotifier;

        const DashboardHeader({
                super.key,
                required this.isConnected,
                required this.connectedDevices,
                required this.batteryVoltageNotifier,
                required this.firmwareNotifier
        });

        @override
        Widget build(BuildContext context) {
                return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                                // Icône + nom (avec ValueListenableBuilder pour le champ name)
                                Expanded(
                                        child: ValueListenableBuilder<RawData?>(
                                                valueListenable: firmwareNotifier,
                                                builder: (ctx, idData, _) {
                                                        String deviceName;
                                                        if (!isConnected) {
                                                                deviceName = 'Non connecté';
                                                        }
                                                        else if (idData != null && (idData.asMap['name']?.isNotEmpty ?? false)) {
                                                                deviceName = idData.asMap['name']!;
                                                        }
                                                        else if (connectedDevices.isNotEmpty) {
                                                                deviceName = connectedDevices.first.productName;
                                                        }
                                                        else {
                                                                deviceName = 'Appareil inconnu';
                                                        }

                                                        return Row(
                                                                children: [
                                                                        Icon(
                                                                                isConnected ? Icons.usb : Icons.usb_off,
                                                                                color: isConnected ? Colors.green : Colors.red
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        Flexible(
                                                                                child: Text(
                                                                                        deviceName,
                                                                                        style: const TextStyle(fontSize: 16),
                                                                                        overflow: TextOverflow.ellipsis
                                                                                )
                                                                        )
                                                                ]
                                                        );
                                                }
                                        )
                                ),

                                // Indicateur de batterie
                                BatteryIndicator(voltageNotifier: batteryVoltageNotifier)
                        ]
                );
        }
}