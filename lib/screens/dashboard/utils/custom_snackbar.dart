/// Fonctions utilitaires pour afficher des SnackBars uniformes dans l'application.

import 'package:flutter/material.dart';

// Construit un SnackBar stylisé avec un [message] et une icône [iconData].
SnackBar buildAppSnackBar({
        required String message,
        IconData iconData = Icons.error,
        Color backgroundColor = Colors.white,
        Color textColor = Colors.black,
        Color iconColor = Colors.black,
        Duration duration = const Duration(seconds: 3),
        BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(12))
}) {
        return SnackBar(
                content: Row(
                        children: [
                                Icon(iconData, color: iconColor, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                        child: Text(
                                                message,
                                                style: TextStyle(color: textColor, fontSize: 16)
                                        )
                                )
                        ]
                ),
                backgroundColor: backgroundColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                duration: duration
        );
}

/// Affiche immédiatement un SnackBar stylisé sur le [ScaffoldMessenger] du contexte.
void showAppSnackBar(
        BuildContext context, {
                required String message,
                IconData iconData = Icons.error,
                Color backgroundColor = Colors.white,
                Color textColor = Colors.black,
                Color iconColor = Colors.black,
                Duration duration = const Duration(seconds: 3),
                BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(12))
        }) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
                buildAppSnackBar(
                        message: message,
                        iconData: iconData,
                        backgroundColor: backgroundColor,
                        textColor: textColor,
                        iconColor: iconColor,
                        duration: duration,
                        borderRadius: borderRadius
                )
        );
}