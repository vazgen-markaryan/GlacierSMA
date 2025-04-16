import 'package:intl/intl.dart';
import '../../../constantes.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import '../../../sensors_data/sensors_data.dart';

class SensorCard extends StatelessWidget {
        const SensorCard({
                super.key,
                required this.info,
                required this.isDebugMode
        });

        final SensorsData info;
        final bool isDebugMode;

        @override
        Widget build(BuildContext context) {
                // Détermine les couleurs et le texte explicatif en fonction de powerStatus
                Color iconColor;
                Color borderColor;
                String statusText;
                switch (info.powerStatus) {
                        case 0:
                                iconColor = Colors.grey;
                                borderColor = Colors.grey;
                                statusText = "Inconnu";
                                break;
                        case 1:
                                iconColor = Colors.green;
                                borderColor = Colors.green;
                                statusText = "Fonctionne";
                                break;
                        case 2:
                                iconColor = Colors.yellow;
                                borderColor = Colors.yellow;
                                statusText = "Déconnecté";
                                break;
                        case 3:
                                iconColor = Colors.red;
                                borderColor = Colors.red;
                                statusText = "Erreur";
                                break;
                        default:
                        iconColor = Colors.black;
                        borderColor = Colors.black;
                        statusText = "Désactivé";
                }

                return GestureDetector(
                        onTap: info.data.isNotEmpty ? () => showSensorDetails(context, info) : null,
                        child: Material(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                                Container(
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
                                                                                height: 50,
                                                                                width: 50,
                                                                                child: SvgPicture.asset(
                                                                                        info.svgSrc!,
                                                                                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)
                                                                                )
                                                                        ),
                                                                        SizedBox(width: defaultPadding),
                                                                        Expanded(
                                                                                child: Text(info.title!, style: Theme.of(context).textTheme.bodyLarge)
                                                                        )
                                                                ]
                                                        )
                                                ),
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
                                                                        statusText,
                                                                        style: TextStyle(
                                                                                color: info.powerStatus == null ? Colors.white : Colors.black, // Texte Blanc pour pour le powerStatus null (déconnecté)
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

        void showSensorDetails(BuildContext context, SensorsData sensor) {
                showDialog(
                        context: context,
                        builder: (context) {
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
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                ValueListenableBuilder<DateTime>(
                                                                        valueListenable: sensor.lastUpdated,
                                                                        builder: (context, timestamp, _) {
                                                                                final formattedTimestamp = DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(timestamp);
                                                                                return Text(
                                                                                        "Mise à jour $formattedTimestamp",
                                                                                        style: const TextStyle(
                                                                                                color: Colors.white54,
                                                                                                fontSize: 14,
                                                                                                fontStyle: FontStyle.italic
                                                                                        )
                                                                                );
                                                                        }
                                                                ),
                                                                const SizedBox(height: 8),
                                                                ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                        valueListenable: sensor.dataNotifier,
                                                                        builder: (context, data, _) {
                                                                                return Column(
                                                                                        children: data.entries.expand((entry) {
                                                                                                        final dataName = entry.key;
                                                                                                        final value = entry.value;
                                                                                                        return [
                                                                                                                Row(
                                                                                                                        children: [
                                                                                                                                SvgPicture.asset(
                                                                                                                                        dataName.svgSrc,
                                                                                                                                        height: 30,
                                                                                                                                        width: 30,
                                                                                                                                        colorFilter: const ColorFilter.mode(
                                                                                                                                                Colors.white70,
                                                                                                                                                BlendMode.srcIn
                                                                                                                                        )
                                                                                                                                ),
                                                                                                                                const SizedBox(width: 12),
                                                                                                                                Expanded(
                                                                                                                                        child: Text(
                                                                                                                                                "${dataName.name} :",
                                                                                                                                                style: const TextStyle(
                                                                                                                                                        color: Colors.white70,
                                                                                                                                                        fontSize: 16
                                                                                                                                                )
                                                                                                                                        )
                                                                                                                                ),
                                                                                                                                const SizedBox(width: 12),
                                                                                                                                Text(
                                                                                                                                        value.toString(),
                                                                                                                                        style: const TextStyle(
                                                                                                                                                color: Colors.white70,
                                                                                                                                                fontSize: 16
                                                                                                                                        ),
                                                                                                                                        textAlign: TextAlign.right
                                                                                                                                )
                                                                                                                        ]
                                                                                                                ),
                                                                                                                const SizedBox(height: 12)
                                                                                                        ];
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
                );
        }
}