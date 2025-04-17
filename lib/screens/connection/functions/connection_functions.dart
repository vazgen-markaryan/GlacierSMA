import 'package:flutter/material.dart';
import '../../dashboard/dashboard_screen.dart';
import 'package:rev_glacier_sma_mobile/constants.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

// Methode qui verifie s'il y a qqch qui est connecté via SERIAL port à telephone
Future<void> getAllCableConnectedDevices(
        FlutterSerialCommunication flutterSerialCommunicationPlugin,
        Function(List<DeviceInfo>) updateDevices) async {
        List<DeviceInfo> devices = await flutterSerialCommunicationPlugin.getAvailableDevices();
        updateDevices(devices);
}

// Methode qui affiche une boite de dialogue pour selectionner un appareil
Future<void> showDeviceSelectionDialog(
        BuildContext context,
        List<DeviceInfo> connectedDevices,
        FlutterSerialCommunication flutterSerialCommunicationPlugin) async {
        // Si rien n'est connecté affiche notification (SnackBar)
        if (connectedDevices.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                                content: Center(
                                        child: Text(
                                                "Aucun appareil trouvé. Vérifiez le câble ou la Switch Hardware.",
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

        // Si des appareils sont disponibles, affiche la boîte de dialogue avec la liste
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
                                                                color: backgroundColor,
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
                                                                        //  Si l'utilisateur clique sur un appareil, essaie de se connecter
                                                                        onTap: () async {
                                                                                bool success = await flutterSerialCommunicationPlugin.connect(device, 115200);
                                                                                // Si la connexion est réussie, navigue vers le DashboardScreen
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
                                                                                // Si la connexion est échouée/refusée, affiche un message d'erreur
                                                                                else {
                                                                                        Navigator.pop(context);
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