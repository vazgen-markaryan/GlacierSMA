/// connection_manager.dart
/// Gestion de la déconnexion utilisateur, manuelle ou automatique (perte de connexion).
/// Utilise des popups pour confirmer ou informer l'utilisateur avant de retourner à l'écran de connexion.

import '../../../constants.dart';
import '../connection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

// Affiche un popup de déconnexion.
// Si [requireConfirmation] est vrai, demande confirmation avant de se déconnecter.
// Sinon, déconnecte immédiatement.
// Retourne "true" si déconnecté, "false" si annulé par l'utilisateur.
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

        // Déconnexion sans confirmation
        await plugin?.disconnect();
        Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ConnectionScreen())
        );
        return true;
}

// Affiche un popup lorsque la connexion est perdue automatiquement.
// Affiche la durée écoulée avant la coupure.
// Déconnecte et retourne à l'écran de connexion.
Future<void> showLostConnectionPopup({
        required BuildContext context,
        required FlutterSerialCommunication? plugin,
        required Duration elapsedTime
}) async {
        final formatted =
                "${elapsedTime.inHours}h ${elapsedTime.inMinutes.remainder(60)}m ${elapsedTime.inSeconds.remainder(60)}s";

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
                                "Connexion perdue après: \n$formatted\n\nVérifiez le câble ou la switch hardware du Debug Mod.",
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