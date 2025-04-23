import '../../../constants.dart';
import 'package:flutter/material.dart';
import '../connection_screen.dart';
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

// Future<void> showLostConnectionPopup({
//         required BuildContext context,
//         required FlutterSerialCommunication? plugin,
// }) async {
//         await showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                         backgroundColor: secondaryColor,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                         title: const Text(
//                                 "Déconnexion",
//                                 style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
//                         ),
//                         content: const Text(
//                                 "Connexion perdue. Vérifiez le câble ou la switch hardware du Debug Mod.",
//                                 style: TextStyle(color: Colors.white70, fontSize: 16),
//                         ),
//                         actions: [
//                                 TextButton(
//                                         onPressed: () => Navigator.of(context).pop(),
//                                         child: const Text("OK", style: TextStyle(color: primaryColor)),
//                                 )
//                         ],
//                 ),
//         );
//
//         await plugin?.disconnect();
//         Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const ConnectionScreen()),
//         );
// }

Future<void> showLostConnectionPopup({
        required BuildContext context,
        required FlutterSerialCommunication? plugin,
        required Duration elapsedTime
}) async {
        final formatted = elapsedTime.toString().split('.').first; // hh:mm:ss

        await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text(
                                "Déconnexion",
                                style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        content: Text(
                                "Connexion perdue après $formatted.\nVérifiez le câble ou la switch hardware du Debug Mod.",
                                style: const TextStyle(color: Colors.white70, fontSize: 16)
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text("OK", style: TextStyle(color: primaryColor))
                                )
                        ]
                )
        );

        await plugin?.disconnect();
        Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ConnectionScreen())
        );
}