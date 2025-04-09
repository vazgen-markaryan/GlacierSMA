import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

import '../constants.dart';
import '../dashboard/dashboard_screen.dart';

class ConnectionScreen extends StatefulWidget {
        const ConnectionScreen({super.key});

        @override
        State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
        final flutterSerialCommunicationPlugin = FlutterSerialCommunication();
        List<DeviceInfo> connectedDevices = [];

        Future<void> getAllConnectedDevices() async {
                List<DeviceInfo> devices = await flutterSerialCommunicationPlugin.getAvailableDevices();
                setState(() {
                                connectedDevices = devices;
                        }
                );
        }

        Future<void> _showDeviceSelectionDialog() async {
                if (connectedDevices.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                        content: Center(
                                                child: Text(
                                                        "Aucun appareil trouvé",
                                                        style: const TextStyle(color: Colors.black, fontSize: 18),
                                                        textAlign: TextAlign.center
                                                )
                                        ),
                                        backgroundColor: Colors.white,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        duration: const Duration(seconds: 2)
                                )
                        );
                        return;
                }

                showDialog(
                        context: context,
                        builder: (BuildContext context) {
                                return AlertDialog(
                                        backgroundColor: secondaryColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text(
                                                "Appareils disponibles",
                                                style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                        ),
                                        content: SizedBox(
                                                width: double.maxFinite,
                                                child: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: connectedDevices.length,
                                                        itemBuilder: (context, index) {
                                                                final device = connectedDevices[index];
                                                                return Card(
                                                                        color: bgColor,
                                                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                        child: ListTile(
                                                                                title: Text(
                                                                                        device.productName,
                                                                                        style: const TextStyle(color: Colors.white, fontSize: 16)
                                                                                ),
                                                                                subtitle: Text(
                                                                                        "ID: ${device.deviceId}",
                                                                                        style: const TextStyle(color: Colors.white70, fontSize: 14)
                                                                                ),
                                                                                onTap: () async {
                                                                                        bool success = await flutterSerialCommunicationPlugin.connect(device, 115200);
                                                                                        if (success) {
                                                                                                Navigator.pushReplacement(
                                                                                                        context,
                                                                                                        MaterialPageRoute(
                                                                                                                builder: (context) => DashboardScreen(
                                                                                                                        flutterSerialCommunicationPlugin: flutterSerialCommunicationPlugin,
                                                                                                                        isConnected: true,
                                                                                                                        connectedDevices: connectedDevices
                                                                                                                )
                                                                                                        )
                                                                                                );
                                                                                        }
                                                                                        else {
                                                                                                Navigator.pop(context); // Ferme la boîte de dialogue
                                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                                        const SnackBar(
                                                                                                                content: Text("Échec de la connexion. Vérifiez le cable ou attribuez la permission.")
                                                                                                        )
                                                                                                );
                                                                                        }
                                                                                }
                                                                        )
                                                                );
                                                        }
                                                )
                                        )
                                );
                        }
                );
        }

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                title: const Center(child: Text('Glacier SMA Connexion'))
                        ),
                        body: LayoutBuilder(
                                builder: (context, constraints) {
                                        bool isHorizontal = constraints.maxWidth > 600;
                                        return Container(
                                                padding: const EdgeInsets.all(16.0),
                                                decoration: const BoxDecoration(color: bgColor),
                                                child: isHorizontal
                                                        ? Row(
                                                                children: [
                                                                        Expanded(child: _buildBluetoothSection()),
                                                                        const SizedBox(width: 16),
                                                                        Expanded(child: _buildCableSection())
                                                                ]
                                                        )
                                                        : Column(
                                                                children: [
                                                                        Expanded(child: _buildBluetoothSection()),
                                                                        const SizedBox(height: 12),
                                                                        _buildArrowInstruction(),
                                                                        const SizedBox(height: 12),
                                                                        Expanded(child: _buildCableSection())
                                                                ]
                                                        )
                                        );
                                }
                        )
                );
        }

        Widget _buildBluetoothSection() {
                return GestureDetector(
                        onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                                content: Center(
                                                        child: Text(
                                                                "Connexion Bluetooth à venir",
                                                                style: const TextStyle(color: Colors.black, fontSize: 18),
                                                                textAlign: TextAlign.center
                                                        )
                                                ),
                                                backgroundColor: Colors.white,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                duration: const Duration(seconds: 2)
                                        )
                                );
                        },
                        child: Card(
                                color: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Center(
                                        child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const[
                                                        Icon(Icons.bluetooth, size: 64, color: Colors.white),
                                                        SizedBox(height: 8),
                                                        Text("Connexion Bluetooth", style: TextStyle(fontSize: 18, color: Colors.white))
                                                ]
                                        )
                                )
                        )
                );
        }

        Widget _buildCableSection() {
                return GestureDetector(
                        onTap: () async {
                                await getAllConnectedDevices();
                                await _showDeviceSelectionDialog();
                        },
                        child: Card(
                                color: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Center(
                                        child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const[
                                                        Icon(Icons.usb_rounded, size: 64, color: Colors.white),
                                                        SizedBox(height: 8),
                                                        Text("Connexion par câble", style: TextStyle(fontSize: 18, color: Colors.white))
                                                ]
                                        )
                                )
                        )
                );
        }

        Widget _buildArrowInstruction() {
                return Row(
                        children: const[
                                Expanded(child: Divider(color: Colors.white24)),
                                Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Column(
                                                children: [
                                                        Icon(Icons.keyboard_arrow_up, color: Colors.white54),
                                                        Text("Sélectionnez une méthode de connexion", style: TextStyle(color: Colors.white54)),
                                                        Icon(Icons.keyboard_arrow_down, color: Colors.white54)
                                                ]
                                        )
                                ),
                                Expanded(child: Divider(color: Colors.white24))
                        ]
                );
        }
}