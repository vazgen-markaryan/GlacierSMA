import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/constantes.dart';

// TODO: Ajouter la fonctionnalité de connexion Bluetooth quand elle sera disponible via Hardware
// Widget qui affiche la section de connexion Bluetooth
Widget buildBluetoothSection(BuildContext context) {
        return GestureDetector(
                onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                        content: Center(
                                                child: Text(
                                                        "Connexion Bluetooth à venir",
                                                        style: const TextStyle(color: Colors.black, fontSize: 18),
                                                        textAlign: TextAlign.center
                                                )
                                        ),
                                        backgroundColor: Colors.white,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        duration: const Duration(seconds: 2)
                                )
                        );
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

// Widget qui crée une flèche avec un texte au milieu seulement pour le Mode Verticale
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

// Widget qui crée une flèche avec un texte au milieu seulement pour le Mode Verticale
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