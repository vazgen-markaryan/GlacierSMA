import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_state.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/hardware_info/hardware_svg.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

class DashboardHeader extends StatelessWidget {
        final List<DeviceInfo> connectedDevices;
        final ValueNotifier<double?> batteryVoltageNotifier;
        final ValueNotifier<RawData?> firmwareNotifier;
        final ValueNotifier<Map<String, double?>> ramNotifier;
        final VoidCallback onRename;

        const DashboardHeader({
                super.key,
                required this.connectedDevices,
                required this.batteryVoltageNotifier,
                required this.ramNotifier,
                required this.firmwareNotifier,
                required this.onRename
        });

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<RawData?>(
                        valueListenable: firmwareNotifier,
                        builder: (_, idData, __) {
                                return ValueListenableBuilder<ConnectionMode>(
                                        valueListenable: GlobalConnectionState.instance.modeNotifier,
                                        builder: (_, mode, __) {
                                                String name;
                                                IconData icon;
                                                Color iconColor;

                                                if (mode == ConnectionMode.usb) {
                                                        icon = Icons.usb;
                                                        iconColor = Colors.green;
                                                        name = (idData?.asMap['name']?.isNotEmpty ?? false)
                                                                ? idData!.asMap['name']!
                                                                : (connectedDevices.isNotEmpty
                                                                        ? connectedDevices.first.productName
                                                                        : tr('home.dashboard.unknown_device'));
                                                }
                                                else if (mode == ConnectionMode.bluetooth) {
                                                        icon = Icons.bluetooth;
                                                        iconColor = Colors.blue;
                                                        name = (idData?.asMap['name']?.isNotEmpty ?? false)
                                                                ? idData!.asMap['name']!
                                                                : tr('home.dashboard.unknown_device');
                                                }
                                                else {
                                                        icon = Icons.usb_off;
                                                        iconColor = Colors.red;
                                                        name = tr('home.dashboard.not_connected');
                                                }

                                                return Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                                Expanded(
                                                                        child: Row(
                                                                                children: [
                                                                                        Icon(icon, color: iconColor),
                                                                                        const SizedBox(width: 8),
                                                                                        Flexible(
                                                                                                child: Text(name, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)
                                                                                        ),
                                                                                        const SizedBox(width: 8),

                                                                                        // Affiche le bouton de renommage SEULEMENT en USB
                                                                                        if (mode == ConnectionMode.usb)
                                                                                        GestureDetector(
                                                                                                onTap: onRename,
                                                                                                child: const Icon(Icons.edit, size: 25, color: Colors.white70)
                                                                                        )
                                                                                ]
                                                                        )
                                                                ),
                                                                HardwareSVG(
                                                                        voltageNotifier: batteryVoltageNotifier,
                                                                        ramNotifier: ramNotifier
                                                                )
                                                        ]
                                                );
                                        }
                                );
                        }
                );
        }
}