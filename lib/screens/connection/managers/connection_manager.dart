/// connection_manager.dart
/// Gère la détection et la sélection des appareils connectés via port série.
/// Affiche une liste des appareils disponibles et empêche le spam de SnackBars.

import 'package:flutter/material.dart';
import '../../dashboard/dashboard_screen.dart';
import 'package:rev_glacier_sma_mobile/constants.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

// Indicateur global pour empêcher l'affichage répété des SnackBars lorsqu'aucun appareil n'est trouvé
bool isShowingDeviceSnackbar = false;

// Récupère tous les appareils connectés via port série et les transmet à la fonction de mise à jour
Future<void> getAllCableConnectedDevices(
        FlutterSerialCommunication flutterSerialCommunicationPlugin,
        Function(List<DeviceInfo>) updateDevices
) async {
        List<DeviceInfo> devices = await flutterSerialCommunicationPlugin.getAvailableDevices();
        updateDevices(devices);
}

// Affiche une boîte de dialogue permettant à l'utilisateur de sélectionner un appareil dans la liste disponible
Future<void> showDeviceSelectionDialog(
        BuildContext context,
        List<DeviceInfo> connectedDevices,
        FlutterSerialCommunication flutterSerialCommunicationPlugin
) async {
        // Si aucun appareil n'est trouvé, afficher un SnackBar et quitter
        if (connectedDevices.isEmpty) {
                if (isShowingDeviceSnackbar) return;

                isShowingDeviceSnackbar = true;

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                                content: Center(
                                        child: Text(
                                                "Aucun appareil trouvé. Vérifiez le câble ou la Switch Hardware.",
                                                style: TextStyle(color: Colors.black, fontSize: 18),
                                                textAlign: TextAlign.center
                                        )
                                ),
                                backgroundColor: Colors.white,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                duration: Duration(seconds: 2)
                        )
                ).closed.then((_) => isShowingDeviceSnackbar = false);

                return;
        }

        // Affiche une boîte de dialogue listant tous les appareils disponibles
        showDialog(
                context: context,
                builder: (BuildContext context) {
                        return AlertDialog(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(
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
                                                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                                                child: ListTile(
                                                                        title: Text(
                                                                                device.productName.isNotEmpty ? device.productName : "Module inconnu",
                                                                                style: TextStyle(color: Colors.white, fontSize: 16)
                                                                        ),
                                                                        subtitle: Text(
                                                                                "ID: ${device.deviceId}",
                                                                                style: TextStyle(color: Colors.white70, fontSize: 14)
                                                                        ),
                                                                        onTap: () async {
                                                                                // Essaie de connecter à l'appareil sélectionné
                                                                                bool success = await flutterSerialCommunicationPlugin.connect(device, 115200);
                                                                                if (success) {
                                                                                        // Si la connexion réussit, ferme la boîte de dialogue et navigue vers l'écran du tableau de bord
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
                                                                                        // Si la connexion échoue, ferme la boîte de dialogue et affiche un SnackBar
                                                                                        Navigator.pop(context);
                                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                                                SnackBar(
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