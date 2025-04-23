import 'package:flutter/material.dart';
import '../../dashboard/dashboard_screen.dart';
import 'package:rev_glacier_sma_mobile/constants.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

// Variable globale pour empêcher le spam de SnackBars
bool isShowingDeviceSnackbar = false;

// Méthode qui vérifie s'il y a des appareils connectés via le port série
Future<void> getAllCableConnectedDevices(
        FlutterSerialCommunication flutterSerialCommunicationPlugin,
        Function(List<DeviceInfo>) updateDevices
) async {
        List<DeviceInfo> devices = await flutterSerialCommunicationPlugin.getAvailableDevices();
        updateDevices(devices);
}

// Méthode qui affiche une boîte de dialogue pour sélectionner un appareil
Future<void> showDeviceSelectionDialog(
        BuildContext context,
        List<DeviceInfo> connectedDevices,
        FlutterSerialCommunication flutterSerialCommunicationPlugin
) async {
        // Aucun appareil trouvé
        if (connectedDevices.isEmpty) {
                if (isShowingDeviceSnackbar) return;

                isShowingDeviceSnackbar = true;

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                ).closed.then((_) => isShowingDeviceSnackbar = false);

                return;
        }

        // Affiche la liste des appareils disponibles
        showDialog(
                context: context,
                builder: (BuildContext context) {
                        return AlertDialog(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text(
                                        "Appareils disponibles",
                                        style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)
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
                                                                                device.productName.isNotEmpty ? device.productName : "Module inconnu",
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
                                                                                        Navigator.pop(context);
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                                const SnackBar(
                                                                                                        content: Text("Échec de la connexion. Vérifiez le câble ou attribuez la permission.")
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