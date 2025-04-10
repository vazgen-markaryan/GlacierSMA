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
                        case 1:
                                iconColor = Colors.green; // Statut 1 : Vert - Marche bien
                                borderColor = Colors.green;
                                break;
                        case 2:
                                iconColor = Colors.yellow; // Statut 2 : Jaune - Pas connecté
                                borderColor = Colors.yellow;
                                break;
                        case 3:
                                iconColor = Colors.red; // Statut 3 : Rouge - Erreur
                                borderColor = Colors.red;
                                break;
                        default:
                        iconColor = Colors.grey; // Status pas encore vérifié
                        borderColor = Colors.grey;
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
                                                        info.title!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: Theme.of(context).textTheme.bodyMedium
                                                )
                                        )
                                ]
                        )
                );
        }
}