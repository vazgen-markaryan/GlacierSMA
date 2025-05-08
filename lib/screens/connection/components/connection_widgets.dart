/// Contient les widgets pour la section de connexion :
/// - buildBluetoothSection : carte Bluetooth
/// - buildCableSection : carte connexion par câble
/// - buildArrowInstruction : guide visuel entre les sections

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

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
                                        children: [
                                                Icon(Icons.bluetooth, size: 64, color: Colors.white),
                                                SizedBox(height: 8),
                                                Text(tr("bluetooth_connection"), style: TextStyle(fontSize: 18, color: Colors.white))
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
                                        children: [
                                                Icon(Icons.usb_rounded, size: 64, color: Colors.white),
                                                SizedBox(height: 8),
                                                Text(tr("cable_connection"), style: TextStyle(fontSize: 18, color: Colors.white))
                                        ]
                                )
                        )
                )
        );
}

// Affiche une flèche avec un texte centré pour indiquer le choix du mode de connexion
Widget buildArrowInstruction() {
        return Row(
                children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                        children: [
                                                Icon(Icons.keyboard_arrow_up, color: Colors.white54),
                                                Text(tr("arrow_instruction"), style: TextStyle(color: Colors.white54)),
                                                Icon(Icons.keyboard_arrow_down, color: Colors.white54)
                                        ]
                                )
                        ),
                        Expanded(child: Divider(color: Colors.white24))
                ]
        );
}