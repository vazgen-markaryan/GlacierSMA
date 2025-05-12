/// Ecran principal de connexion pour Glacier SMA.
/// Affiche les options de connexion Bluetooth et câble,
/// Gère la détection des appareils via USB série.

import 'package:flutter/material.dart';
import 'components/connection_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/components/connection_widgets.dart';

class ConnectionScreen extends StatefulWidget {
        const ConnectionScreen({super.key});

        @override
        State<ConnectionScreen> createState() => ConnectionScreenState();
}

class ConnectionScreenState extends State<ConnectionScreen> {
        // Plugin pour la communication série
        final flutterSerialCommunicationPlugin = FlutterSerialCommunication();
        // Liste des dispositifs disponibles
        List<DeviceInfo> connectedDevices = [];

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                automaticallyImplyLeading: false,
                                title: Center(child: Text(tr("connection.appTitle")))
                        ),
                        body: LayoutBuilder(
                                builder: (context, constraints) {
                                        // Détermine l'orientation selon la largeur de l'écran
                                        bool isHorizontal = constraints.maxWidth > 700;

                                        return Container(
                                                padding: const EdgeInsets.all(defaultPadding),
                                                decoration: const BoxDecoration(color: backgroundColor),
                                                child: isHorizontal
                                                        // Mode horizontal : Bluetooth à gauche, câble à droite
                                                        ? Row(
                                                                children: [
                                                                        Expanded(
                                                                                child: buildBluetoothSection(context)
                                                                        ),
                                                                        const SizedBox(width: defaultPadding),
                                                                        Expanded(
                                                                                child: buildCableSection(context, () async {
                                                                                                // 1. Récupère et affiche la liste
                                                                                                await getAllCableConnectedDevices(
                                                                                                        flutterSerialCommunicationPlugin,
                                                                                                        (devices) => setState(() => connectedDevices = devices)
                                                                                                );
                                                                                                // 2. Ouvre le dialogue, attend la fermeture (sélection ou annulation)
                                                                                                await showDeviceSelectionDialog(
                                                                                                        context,
                                                                                                        connectedDevices,
                                                                                                        flutterSerialCommunicationPlugin
                                                                                                );
                                                                                                // 3. Quand le dialogue est fermé, on vide les appareils
                                                                                                setState(() => connectedDevices.clear());
                                                                                        }
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                        // Mode vertical : Bluetooth en haut, instructions, câble en bas
                                                        : Column(
                                                                children: [
                                                                        Expanded(child: buildBluetoothSection(context)),
                                                                        const SizedBox(height: defaultPadding * 0.75),
                                                                        buildArrowInstruction(),
                                                                        const SizedBox(height: defaultPadding * 0.75),
                                                                        Expanded(
                                                                                child: buildCableSection(
                                                                                        context, () async {
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