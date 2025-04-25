/// Contient les widgets pour la section de connexion :
/// - buildBluetoothSection : carte Bluetooth
/// - buildCableSection : carte connexion par câble
/// - buildArrowInstruction : guide visuel entre les sections

import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/utils/constants.dart';

// Affiche une carte pour la connexion Bluetooth
Widget buildBluetoothSection(BuildContext context) {
        return GestureDetector(
                onTap: () {
                        // TODO : Ajouter la fonctionnalité de connexion Bluetooth via le hardware
                },
                child: Card(
                        color: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Center(
                                child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const[
                                                Icon(Icons.bluetooth, size: 64, color: Colors.white),
                                                SizedBox(height: 8),
                                                Text("Connexion Bluetooth", style: TextStyle(fontSize: 18, color: Colors.white))
                                        ]
                                )
                        )
                )
        );
}

// Affiche une carte pour la connexion par câble
Widget buildCableSection(BuildContext context, Function onTap) {
        return GestureDetector(
                onTap: () async => onTap(),
                child: Card(
                        color: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Center(
                                child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const[
                                                Icon(Icons.usb_rounded, size: 64, color: Colors.white),
                                                SizedBox(height: 8),
                                                Text("Connexion par câble", style: TextStyle(fontSize: 18, color: Colors.white))
                                        ]
                                )
                        )
                )
        );
}

// Affiche une flèche avec un texte centré pour indiquer le choix du mode de connexion
Widget buildArrowInstruction() {
        return Row(
                children: const[
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                        children: [
                                                Icon(Icons.keyboard_arrow_up, color: Colors.white54),
                                                Text("Sélectionnez une méthode de connexion", style: TextStyle(color: Colors.white54)),
                                                Icon(Icons.keyboard_arrow_down, color: Colors.white54)
                                        ]
                                )
                        ),
                        Expanded(child: Divider(color: Colors.white24))
                ]
        );
}