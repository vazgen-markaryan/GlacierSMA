/// Gère la détection et la sélection des appareils connectés via port série.
/// Affiche uniquement les appareils dont le nom contient "RevGlacierSMA".
/// Si aucun n'est compatible, affiche un SnackBar d'information.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';

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
                .where((device) => device.productName.contains('RevGlacierSMA'))
                .toList();

        // Aucun appareil compatible
        if (compatibleDevices.isEmpty) {
                if (isShowingDeviceSnackbar) return;
                isShowingDeviceSnackbar = true;

                final controller = ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar(
                                message: tr("connection.no_device_found"),
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
                        title: Text(tr("connection.devices_found"),
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
                                                                                                builder: (_) => Home_Screen(
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
                                                                                        message: tr("connection.failed_to_connect")
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

/// Gère les popups de déconnexion utilisateur et de perte de connexion automatique.
/// Utilise CustomPopup pour un style uniforme, puis déconnecte et retourne à l’écran de connexion.
/// Affiche un popup pour confirmer une déconnexion manuelle si [requireConfirmation] est vrai.
/// Sinon, déconnecte immédiatement sans confirmation.
/// Retourne `true` si la déconnexion a eu lieu, `false` si l’utilisateur a annulé.
Future<bool> showDisconnectPopup({
        required BuildContext context,
        required FlutterSerialCommunication? plugin,
        bool requireConfirmation = false
}) async {
        if (requireConfirmation) {
                // Affiche le CustomPopup et attend la réponse true/false
                final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => CustomPopup(
                                title: tr("connection.disconnect"),
                                content: Text(tr("connection.disconnect_confirmation"),
                                        style: TextStyle(color: Colors.white)
                                ),
                                actions: [
                                        TextButton(
                                                // Action "Non" : renvoie false
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: Text(tr("no"), style: TextStyle(color: primaryColor))
                                        ),
                                        TextButton(
                                                // Action "Oui" : renvoie true
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: Text(tr("yes"), style: TextStyle(color: primaryColor))
                                        )
                                ]
                        )
                );

                if (result == true) {
                        // L’utilisateur a confirmé : déconnexion et retour à l’écran de connexion
                        await plugin?.disconnect();
                        Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const ConnectionScreen())
                        );
                        return true;
                }
                // L’utilisateur a annulé
                return false;
        }

        // Déconnexion sans confirmation
        await plugin?.disconnect();
        Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ConnectionScreen())
        );
        return true;
}