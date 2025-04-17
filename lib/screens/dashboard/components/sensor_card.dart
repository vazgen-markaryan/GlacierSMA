import 'sensors_data.dart';
import '../../../constants.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/components/sensor_details_popup.dart';

class SensorCard extends StatelessWidget {
        final SensorsData sensorData;
        final bool isDebugMode;

        const SensorCard({
                super.key,
                required this.sensorData,
                required this.isDebugMode
        });

        @override
        Widget build(BuildContext context) {
                final (iconColor, borderColor, statusLabel) = getStatusUI(sensorData.powerStatus);

                return GestureDetector(
                        onTap: sensorData.data.isNotEmpty ? () => showSensorPopup(context, sensorData) : null,
                        child: Material(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                                Container(
                                                        padding: EdgeInsets.all(defaultPadding),
                                                        decoration: BoxDecoration(
                                                                color: secondaryColor,
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(color: borderColor, width: 3)
                                                        ),
                                                        child: Row(
                                                                children: [
                                                                        LayoutBuilder(
                                                                                builder: (context, constraints) {
                                                                                        final iconSize = constraints.maxHeight;
                                                                                        return SvgPicture.asset(
                                                                                                sensorData.svgIcon!,
                                                                                                height: iconSize,
                                                                                                width: iconSize,
                                                                                                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)
                                                                                        );
                                                                                }
                                                                        ),
                                                                        SizedBox(width: defaultPadding),
                                                                        Expanded(
                                                                                child: Text(
                                                                                        sensorData.title ?? "Capteur inconnu",
                                                                                        style: Theme.of(context).textTheme.bodyLarge
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                ),
                                                // Pastille de PowerStatus
                                                Positioned(
                                                        top: -10,
                                                        right: -10,
                                                        child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                        color: iconColor,
                                                                        borderRadius: const BorderRadius.only(
                                                                                bottomLeft: Radius.circular(10),
                                                                                topRight: Radius.circular(10)
                                                                        )
                                                                ),
                                                                child: Text(
                                                                        statusLabel,
                                                                        style: TextStyle(
                                                                                color: sensorData.powerStatus == null ? Colors.white : Colors.black,
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.bold
                                                                        )
                                                                )
                                                        )
                                                )
                                        ]
                                )
                        )
                );
        }

        (Color iconColor, Color borderColor, String label) getStatusUI(int? status) {
                switch (status) {
                        case 0: return (Colors.grey, Colors.grey, "Inconnu");
                        case 1: return (Colors.green, Colors.green, "Fonctionne");
                        case 2: return (Colors.yellow, Colors.yellow, "Déconnecté");
                        case 3: return (Colors.red, Colors.red, "Erreur");
                        default: return (Colors.black, Colors.black, "Désactivé");
                }
        }

        void showSensorPopup(BuildContext context, SensorsData sensor) {
                showDialog(
                        context: context,
                        builder: (context) => SensorDetailsDialog(sensor: sensor)
                );
        }
}