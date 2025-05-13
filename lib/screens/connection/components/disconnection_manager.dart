/// Gère les popups de déconnexion utilisateur et de perte de connexion automatique.
/// Utilise CustomPopup pour un style uniforme, puis déconnecte et retourne à l’écran de connexion.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';

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

/// Affiche un popup d’information quand la connexion est perdue automatiquement.
/// Affiche la durée écoulée avant la coupure, puis déconnecte et retourne à l’écran de connexion.
Future<void> showLostConnectionPopup({
        required BuildContext context,
        required FlutterSerialCommunication? plugin,
        required Duration elapsedTime
}) async {
        // Formate la durée écoulée en h m s
        final formatted = "${elapsedTime.inHours}h ${elapsedTime.inMinutes.remainder(60)}m ${elapsedTime.inSeconds.remainder(60)}s";

        // Affiche le CustomPopup avec le message d’erreur
        await showDialog(
                context: context,
                builder: (_) => CustomPopup(
                        title: tr("connection.disconnect"),
                        content: Text(
                                tr('connection.lost_connection', namedArgs: {'time': formatted}),
                                style: const TextStyle(color: Colors.white70)
                        ),
                        actions: [
                                TextButton(
                                        // Fermeture du popup
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK', style: TextStyle(color: primaryColor))
                                )
                        ]
                )
        );

        // Après fermeture, déconnecte et retourne à l’écran de connexion
        await plugin?.disconnect();
        Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ConnectionScreen())
        );
}