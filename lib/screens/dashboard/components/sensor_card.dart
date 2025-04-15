import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../constantes.dart';
import '../../../sensors_data/sensors_data.dart';

class SensorCard extends StatelessWidget {
        const SensorCard({
                super.key,
                required this.info,
                required this.isDebugMode
        });

        final Sensors info;
        final bool isDebugMode;

        @override
        Widget build(BuildContext context) {
                // Détermine les couleurs en fonction de powerStatus
                Color iconColor;
                Color borderColor;
                switch (info.powerStatus) {
                        case 0:
                                iconColor = Colors.grey; // Status 0 : Gris - Pas vérifié/Inconnu
                                borderColor = Colors.grey;
                                break;
                        case 1:
                                iconColor = Colors.green; // Status 1 : Vert - Marche bien
                                borderColor = Colors.green;
                                break;
                        case 2:
                                iconColor = Colors.yellow; // Status 2 : Jaune - Pas connecté
                                borderColor = Colors.yellow;
                                break;
                        case 3:
                                iconColor = Colors.red; // Status 3 : Rouge - Erreur
                                borderColor = Colors.red;
                                break;
                        default:
                        iconColor = Colors.black; // Status Default : Noir - Autre que 0, 1, 2 ou 3
                        borderColor = Colors.black;
                }

                return GestureDetector(
                        onTap: info.data.isNotEmpty ? () => showSensorDetails(context, info) : null, // Désactiver le clic si data est vide (SD Card)
                        child: Container(
                                padding: EdgeInsets.all(defaultPadding),
                                decoration: BoxDecoration(
                                        color: secondaryColor,
                                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        border: Border.all(color: borderColor, width: 3)
                                ),
                                child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                                Container(
                                                        padding: EdgeInsets.all(defaultPadding / 8),
                                                        height: 30,
                                                        width: 30,
                                                        decoration: BoxDecoration(
                                                                borderRadius: const BorderRadius.all(Radius.circular(5))
                                                        ),
                                                        child: SvgPicture.asset(
                                                                info.svgSrc!,
                                                                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)
                                                        )
                                                ),
                                                SizedBox(width: defaultPadding),
                                                // Texte
                                                Expanded(
                                                        child: Text(
                                                                isDebugMode
                                                                        ? "Status: ${info.powerStatus}\n${info.title!}"
                                                                        : info.title!,
                                                                overflow: TextOverflow.visible,
                                                                softWrap: true,
                                                                maxLines: 2, // Limite à 2 lignes
                                                                style: Theme.of(context).textTheme.bodyMedium
                                                        )
                                                )
                                        ]
                                )
                        )
                );
        }

        void showSensorDetails(BuildContext context, Sensors sensor) {
                showDialog(
                        context: context,
                        builder: (context) {
                                return AlertDialog(
                                        backgroundColor: secondaryColor,
                                        shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16)
                                        ),
                                        title: Text(
                                                sensor.title ?? "Détails du capteur",
                                                style: const TextStyle(
                                                        color: primaryColor,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold
                                                )
                                        ),
                                        content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: sensor.data.entries.map((entry) {
                                                                final dataName = entry.key;
                                                                final value = entry.value;
                                                                return Row(
                                                                        children: [
                                                                                SvgPicture.asset(
                                                                                        dataName.svgSrc,
                                                                                        height: 24,
                                                                                        width: 24,
                                                                                        colorFilter: const ColorFilter.mode(
                                                                                                Colors.white70,
                                                                                                BlendMode.srcIn
                                                                                        )
                                                                                ),
                                                                                const SizedBox(width: 8),
                                                                                Text(
                                                                                        "${dataName.name}: $value",
                                                                                        style: const TextStyle(
                                                                                                color: Colors.white70,
                                                                                                fontSize: 16
                                                                                        )
                                                                                )
                                                                        ]
                                                                );
                                                        }
                                                ).toList()
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
                );
        }
}