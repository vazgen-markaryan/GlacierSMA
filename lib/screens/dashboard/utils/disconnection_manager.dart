import '../../../constants.dart';
import 'package:flutter/material.dart';
import '../../connection/connection_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

Future<bool> showDisconnectPopup({
        required BuildContext context,
        required FlutterSerialCommunication? plugin,
        bool requireConfirmation = false
}) async {
        if (requireConfirmation) {
                final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                                backgroundColor: secondaryColor,
                                title: const Text("Déconnexion", style: TextStyle(color: primaryColor)),
                                content: const Text("Voulez-vous vraiment vous déconnecter ?"),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text("Non", style: TextStyle(color: Colors.white))
                                        ),
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text("Oui", style: TextStyle(color: primaryColor))
                                        )
                                ]
                        )
                );

                if (result == true) {
                        await plugin?.disconnect();
                        Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ConnectionScreen())
                        );
                        return true;
                }
                else {
                        return false;
                }
        }

        // Appel automatique en cas de déconnexion (sans confirmation)
        await plugin?.disconnect();
        Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ConnectionScreen())
        );
        return true;
}