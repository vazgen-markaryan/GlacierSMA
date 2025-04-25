/// Widget pour l’en-tête du Dashboard : statut USB, batterie et toggle debug,
/// avec gestion de l’overflow pour que le texte ne déborde pas.

import '../debug/debug_toggle.dart';
import 'package:flutter/material.dart';
import '../battery/battery_indicator.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

class DashboardHeader extends StatelessWidget {
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;
        final bool isDebugVisible;
        final VoidCallback onToggleDebug;
        final ValueNotifier<double?> batteryVoltageNotifier;

        const DashboardHeader({
                super.key,
                required this.isConnected,
                required this.connectedDevices,
                required this.isDebugVisible,
                required this.onToggleDebug,
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

                                // Zone droite : batterie + toggle debug
                                Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                BatteryIndicator(voltageNotifier: batteryVoltageNotifier),
                                                const SizedBox(width: 12),
                                                DebugToggleButton(
                                                        isDebugVisible: isDebugVisible,
                                                        onToggle: onToggleDebug
                                                )
                                        ]
                                )
                        ]
                );
        }
}