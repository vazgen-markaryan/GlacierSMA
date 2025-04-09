import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import '../../constants.dart';
import '../../sensors_data/sensors_data.dart';
import '../connection/connection_screen.dart';
import 'components/sensors.dart';

class DashboardScreen extends StatefulWidget {
        final FlutterSerialCommunication? flutterSerialCommunicationPlugin;
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;

        const DashboardScreen({
                super.key,
                required this.flutterSerialCommunicationPlugin,
                required this.isConnected,
                required this.connectedDevices
        });

        @override
        State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
        late bool isConnected;
        Timer? connectionCheckTimer;

        @override
        void initState() {
                super.initState();
                isConnected = widget.isConnected;

                // Vérification périodique de l'état de connexion
                connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
                                bool isMessageSent = await sendMessage("ping");
                                if (!isMessageSent && isConnected) {
                                        setState(() => isConnected = false);
                                        _showDisconnectionDialog();
                                }
                        }
                );
        }

        @override
        void dispose() {
                connectionCheckTimer?.cancel();
                super.dispose();
        }

        Future<void> _showDisconnectionDialog() async {
                await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text(
                                        "Déconnexion",
                                        style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                                content: const Text(
                                        "Connexion perdue. Vérifiez le câble.",
                                        style: TextStyle(color: Colors.white70, fontSize: 16)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () {
                                                        Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                        "OK",
                                                        style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                                                )
                                        )
                                ]
                        )
                );

                // Déconnecter après la boîte de dialogue
                await disconnect();
        }

        Future<void> disconnect() async {
                await widget.flutterSerialCommunicationPlugin?.disconnect();
                setState(() {
                                isConnected = false;
                        }
                );

                // Redirection vers l'écran de connexion
                Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ConnectionScreen())
                );
        }

        Future<bool> sendMessage(String message) async {
                Uint8List data = convertStringToUint8List(message);
                try {
                        bool isMessageSent = await widget.flutterSerialCommunicationPlugin?.write(data) ?? false;
                        return isMessageSent;
                }
                catch (e) {
                        return false;
                }
        }

        Uint8List convertStringToUint8List(String input) {
                return Uint8List.fromList(input.codeUnits);
        }

        Future<void> _showDisconnectConfirmationDialog(BuildContext context) async {
                final shouldDisconnect = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text(
                                        "Déconnexion",
                                        style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                                content: const Text(
                                        "Voulez-vous vraiment vous déconnecter ?",
                                        style: TextStyle(color: Colors.white70, fontSize: 16)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(false), // Annuler
                                                child: const Text(
                                                        "Non",
                                                        style: TextStyle(color: Colors.white, fontSize: 16)
                                                )
                                        ),
                                        TextButton(
                                                onPressed: () async {
                                                        await widget.flutterSerialCommunicationPlugin?.disconnect();
                                                        Navigator.of(context).pop(true); // Confirmer
                                                },
                                                child: const Text(
                                                        "Oui",
                                                        style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                                                )
                                        )
                                ]
                        )
                ) ??
                        false;

                if (shouldDisconnect) {
                        ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                        content: Text("Déconnecté avec succès.")
                                )
                        );

                        // Redirection vers l'écran de connexion
                        Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ConnectionScreen())
                        );
                }
        }

        Widget buildConnectionStatus() {
                return Row(
                        children: [
                                Icon(isConnected ? Icons.usb : Icons.usb_off, color: isConnected ? Colors.green : Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                        isConnected
                                                ? (widget.connectedDevices.isNotEmpty ? widget.connectedDevices.first.productName : "Appareil inconnu")
                                                : "Non connecté",
                                        style: const TextStyle(fontSize: 16)
                                )
                        ]
                );
        }

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                automaticallyImplyLeading: false,
                                backgroundColor: secondaryColor,
                                title: buildConnectionStatus(),
                                actions: [
                                        IconButton(
                                                icon: const Icon(Icons.logout, color: Colors.white),
                                                onPressed: () => _showDisconnectConfirmationDialog(context)
                                        )
                                ]
                        ),
                        body: SafeArea(
                                child: SingleChildScrollView(
                                        primary: false,
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                children: [
                                                        SizedBox(height: defaultPadding),
                                                        Row(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        Expanded(
                                                                                flex: 5,
                                                                                child: Column(
                                                                                        children: [
                                                                                                MySensors(
                                                                                                        title: "Les Capteurs Internes",
                                                                                                        sensors: internalSensors
                                                                                                ),
                                                                                                SizedBox(height: defaultPadding),
                                                                                                MySensors(
                                                                                                        title: "Les Capteurs du Vent",
                                                                                                        sensors: windSensors
                                                                                                ),
                                                                                                SizedBox(height: defaultPadding),
                                                                                                MySensors(
                                                                                                        title: "Les Capteurs Stevenson",
                                                                                                        sensors: stevensonSensors
                                                                                                ),
                                                                                                SizedBox(height: defaultPadding)
                                                                                        ]
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                ]
                                        )
                                )
                        )
                );
        }
}