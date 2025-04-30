/// Gère la détection et la sélection des appareils connectés via port série.
/// Affiche uniquement les appareils dont le nom contient "RevGlacierSMA".
/// Si aucun n'est compatible, affiche un SnackBar d'information.

import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

// Indicateur global pour empêcher le spam de SnackBars
bool isShowingDeviceSnackbar = false;

// Récupère tous les appareils disponibles et les passe à [updateDevices].
Future<void> getAllCableConnectedDevices(
        FlutterSerialCommunication plugin,
        void Function(List<DeviceInfo>) updateDevices
) async {
        final devices = await plugin.getAvailableDevices();
        updateDevices(devices);
}

// Affiche un dialogue pour sélectionner un appareil "RevGlacierSMA".
// Si aucun compatible n'est détecté, affiche un SnackBar dédié.
Future<void> showDeviceSelectionDialog(
        BuildContext context,
        List<DeviceInfo> connectedDevices,
        FlutterSerialCommunication plugin
) async {
        // Filtrer les appareils pour ne garder que les noms contenant "RevGlacierSMA"
        final compatibleDevices = connectedDevices
                .where((d) => d.productName.contains('RevGlacierSMA'))
                .toList();

        // Aucun appareil compatible
        if (compatibleDevices.isEmpty) {
                if (isShowingDeviceSnackbar) return;
                isShowingDeviceSnackbar = true;

                final controller = ScaffoldMessenger.of(context).showSnackBar(
                        buildAppSnackBar(
                                message:
                                "Aucun appareil compatible n'est trouvé:\n1. Flashez le code RevGlacierSMA\n2. Vérifiez le câble\n3. Vérifiez le Debug Switch physique.",
                                iconData: Icons.error,
                                backgroundColor: Colors.white,
                                textColor: Colors.black,
                                iconColor: Colors.black
                        )
                );

                controller.closed.then((_) => isShowingDeviceSnackbar = false);
                return;
        }

        // Afficher la liste des appareils compatibles
        showDialog(
                context: context,
                builder: (_) => AlertDialog(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                                "Appareils détectés",
                                style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold
                                )
                        ),
                        content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: compatibleDevices.length,
                                        itemBuilder: (context, index) {
                                                final device = compatibleDevices[index];
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
                                                                onTap: () async {
                                                                        final success = await plugin.connect(device, 115200);
                                                                        if (success) {
                                                                                // Naviguer vers Dashboard
                                                                                Navigator.pushReplacement(
                                                                                        context,
                                                                                        MaterialPageRoute(
                                                                                                builder: (_) => home_screen(
                                                                                                        plugin: plugin,
                                                                                                        isConnected: true,
                                                                                                        connectedDevices: compatibleDevices
                                                                                                )
                                                                                        )
                                                                                );
                                                                        }
                                                                        else {
                                                                                // Échec de connexion
                                                                                Navigator.pop(context);
                                                                                showCustomSnackBar(
                                                                                        context,
                                                                                        message:
                                                                                        "Échec de la connexion. Vérifiez le câble ou les permissions."
                                                                                );
                                                                        }
                                                                }
                                                        )
                                                );
                                        }
                                )
                        )
                )
        );
}