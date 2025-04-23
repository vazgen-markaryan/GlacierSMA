import '../../../constants.dart';
import 'package:flutter/material.dart';
import '../../connection/connection_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

Future<void> showDisconnectionDialog(
        BuildContext context,
        Future<void> Function() onDisconnect
) async {
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
                                "Connexion perdue. Vérifiez le câble ou la switch hardware du Debug Mod",
                                style: TextStyle(color: Colors.white70, fontSize: 16)
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text("OK", style: TextStyle(color: primaryColor))
                                )
                        ]
                )
        );

        await onDisconnect();
}

Future<void> handleDisconnection(
        BuildContext context,
        FlutterSerialCommunication? plugin
) async {
        await plugin?.disconnect();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConnectionScreen()));
}