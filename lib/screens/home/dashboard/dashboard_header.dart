/// Widget pour l’en-tête du Dashboard : statut USB, batterie et toggle components, avec gestion de l’overflow pour que le texte ne déborde pas.

import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/battery/battery_indicator.dart';

class DashboardHeader extends StatelessWidget {
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;
        final ValueNotifier<double?> batteryVoltageNotifier;

        const DashboardHeader({
                super.key,
                required this.isConnected,
                required this.connectedDevices,
                required this.batteryVoltageNotifier
        });

        @override
        Widget build(BuildContext context) {
                return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                                // Zone gauche : icône + nom de l'appareil, ellipsisé si trop long
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
                                                                        isConnected
                                                                                ? (connectedDevices.isNotEmpty
                                                                                        ? connectedDevices.first.productName
                                                                                        : 'Appareil inconnu')
                                                                                : 'Non connecté',
                                                                        style: const TextStyle(fontSize: 16),
                                                                        overflow: TextOverflow.ellipsis
                                                                )
                                                        )
                                                ]
                                        )
                                ),
                                BatteryIndicator(voltageNotifier: batteryVoltageNotifier)
                        ]
                );
        }
}