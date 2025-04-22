import 'package:flutter/material.dart';
import 'functions/connection_functions.dart';
import 'package:rev_glacier_sma_mobile/constants.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/widgets/connection_widgets.dart';

class ConnectionScreen extends StatefulWidget {
        const ConnectionScreen({super.key});

        @override
        State<ConnectionScreen> createState() => ConnectionScreenState();
}

class ConnectionScreenState extends State<ConnectionScreen> {
        final flutterSerialCommunicationPlugin = FlutterSerialCommunication();
        List<DeviceInfo> connectedDevices = [];

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(title: const Center(child: Text('Glacier SMA Connexion'))),
                        body: LayoutBuilder(
                                builder: (context, constraints) {
                                        bool isHorizontal = constraints.maxWidth > 600;
                                        // Si l'écran est horizontal, on affiche la section Bluetooth à gauche et la section câble à droite
                                        return Container(
                                                padding: const EdgeInsets.all(16.0),
                                                decoration: const BoxDecoration(color: backgroundColor),
                                                child: isHorizontal
                                                        ? Row(
                                                                children: [
                                                                        Expanded(child: buildBluetoothSection(context)),
                                                                        const SizedBox(width: 16),
                                                                        Expanded(
                                                                                child: buildCableSection(context, () async {
                                                                                                await getAllCableConnectedDevices(
                                                                                                        flutterSerialCommunicationPlugin,
                                                                                                        (devices) => setState(() => connectedDevices = devices)
                                                                                                );
                                                                                                await showDeviceSelectionDialog(
                                                                                                        context,
                                                                                                        connectedDevices,
                                                                                                        flutterSerialCommunicationPlugin
                                                                                                );
                                                                                        }
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                        // Si l'écran est vertical, on affiche la section Bluetooth en haut et la section câble en bas
                                                        : Column(
                                                                children: [
                                                                        Expanded(child: buildBluetoothSection(context)),
                                                                        const SizedBox(height: 12),
                                                                        buildArrowInstruction(),
                                                                        const SizedBox(height: 12),
                                                                        Expanded(
                                                                                child: buildCableSection(context, () async {
                                                                                                await getAllCableConnectedDevices(
                                                                                                        flutterSerialCommunicationPlugin,
                                                                                                        (devices) => setState(() => connectedDevices = devices)
                                                                                                );
                                                                                                await showDeviceSelectionDialog(
                                                                                                        context,
                                                                                                        connectedDevices,
                                                                                                        flutterSerialCommunicationPlugin
                                                                                                );
                                                                                        }
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                        );
                                }
                        )
                );
        }
}