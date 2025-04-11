import '../../../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../sensors_data/sensors_data.dart';

class SensorCard extends StatelessWidget {
        const SensorCard({
                super.key,
                required this.info
        });

        final CloudStorageInfo info;

        @override
        Widget build(BuildContext context) {
                // Détermine les couleurs en fonction de powerStatus
                Color iconColor;
                Color borderColor;
                switch (info.powerStatus) {
                        case 0:
                                //TODO ajouter loading truc
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

                return Container(
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
                                                        info.powerStatus.toString() + info.title!,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: Theme.of(context).textTheme.bodyMedium
                                                )
                                        )
                                ]
                        )
                );
        }
}