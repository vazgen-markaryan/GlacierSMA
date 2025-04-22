import 'dart:async';

import 'sensors_data.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';

// Popup qui affiche les détails d’un capteur spécifique.
// Affiche la dernière mise à jour et les données disponibles (nom + valeur + icône).
class SensorDetailsPopup extends StatelessWidget {

        final SensorsData sensor;
        const SensorDetailsPopup({super.key, required this.sensor});

        @override
        Widget build(BuildContext context) {
                return AlertDialog(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                                sensor.title ?? "Détails du capteur",
                                style: const TextStyle(
                                        color: primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold
                                )
                        ),
                        content: SingleChildScrollView(
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                // Affichage du timestamp formaté
                                                StatefulBuilder(
                                                        builder: (context, setState) {
                                                                final now = DateTime.now();
                                                                final formatted = DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(now);

                                                                // Redémarre l’horloge toutes les secondes
                                                                Timer(const Duration(seconds: 1), () => setState(() {
                                                                                }
                                                                        )
                                                                );

                                                                return Text(
                                                                        "Mise à jour $formatted",
                                                                        style: const TextStyle(
                                                                                color: Colors.white54,
                                                                                fontSize: 14,
                                                                                fontStyle: FontStyle.italic
                                                                        )
                                                                );
                                                        }
                                                ),

                                                const SizedBox(height: 8),

                                                // Affichage des données (nom + valeur + icône)
                                                ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                        valueListenable: sensor.dataNotifier,
                                                        builder: (context, data, _) {
                                                                return Column(
                                                                        children: data.entries.map(
                                                                                (entry) {
                                                                                        final key = entry.key;
                                                                                        final value = entry.value;

                                                                                        return Padding(
                                                                                                padding: const EdgeInsets.only(bottom: 12),
                                                                                                child: Row(
                                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                        children: [
                                                                                                                // Icone + nom du capteur
                                                                                                                Expanded(
                                                                                                                        child: Row(
                                                                                                                                children: [
                                                                                                                                        SvgPicture.asset(
                                                                                                                                                key.svgLogo,
                                                                                                                                                height: 25,
                                                                                                                                                width: 25,
                                                                                                                                                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                                                                                                        ),
                                                                                                                                        const SizedBox(width: 10),
                                                                                                                                        Flexible(
                                                                                                                                                child: Text(
                                                                                                                                                        "${key.name}: ",
                                                                                                                                                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                                                                                                                                                        overflow: TextOverflow.ellipsis
                                                                                                                                                )
                                                                                                                                        )
                                                                                                                                ]
                                                                                                                        )
                                                                                                                ),

                                                                                                                // Valeur alignée à droite
                                                                                                                Text(
                                                                                                                        value.toString(),
                                                                                                                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                                                                                                                        textAlign: TextAlign.right,
                                                                                                                        overflow: TextOverflow.ellipsis
                                                                                                                )
                                                                                                        ]
                                                                                                )
                                                                                        );
                                                                                }
                                                                        ).toList()
                                                                );
                                                        }
                                                )
                                        ]
                                )
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text(
                                                "Fermer",
                                                style: TextStyle(
                                                        color: primaryColor,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                )
                                        )
                                )
                        ]
                );
        }
}