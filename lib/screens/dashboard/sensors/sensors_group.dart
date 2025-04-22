import 'sensors_data.dart';
import '../../../constants.dart';
import 'sensor_details_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Notifie automatiquement le widget lorsqu’un capteur du groupe change.
// Permet de rebuild les capteurs dès que leur `dataNotifier` change.
class SensorsGroupNotifier extends ValueNotifier<int> {
        SensorsGroupNotifier(List<SensorsData> sensors) : super(0) {
                for (var sensor in sensors) {
                        sensor.dataNotifier.addListener(onChange);
                }
        }

        void onChange() => value++; // Déclenche un rebuild
}

// Widget principal qui affiche un groupe de capteurs avec un titre et une grille des capteurs visibles.
class SensorsGroup extends StatelessWidget {
        final String title;
        final List<SensorsData> sensors;
        final bool isDebugMode;

        const SensorsGroup({
                super.key,
                required this.title,
                required this.sensors,
                required this.isDebugMode
        });

        @override
        Widget build(BuildContext context) {
                final notifier = SensorsGroupNotifier(sensors);

                return ValueListenableBuilder<int>(
                        valueListenable: notifier,
                        builder: (context, _, __) {
                                // Filtrer les capteurs si on n’est pas en debug
                                final filtered = sensors.where((s) => isDebugMode || s.powerStatus != null);

                                return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                Text(title, style: Theme.of(context).textTheme.titleMedium),
                                                const SizedBox(height: defaultPadding),
                                                Wrap(
                                                        spacing: defaultPadding,
                                                        runSpacing: defaultPadding,
                                                        children: filtered.map((sensor) => buildSensorCard(context, sensor)).toList()
                                                )
                                        ]
                                );
                        }
                );
        }

        //Construit une carte individuelle pour chaque capteur
        Widget buildSensorCard(BuildContext context, SensorsData sensor) {
                final (iconColor, borderColor, statusLabel) = getStatusUI(sensor.powerStatus);

                return SizedBox(
                        width: double.infinity,
                        height: 85,
                        child: GestureDetector(
                                onTap: sensor.data.isNotEmpty ? () => showSensorPopup(context, sensor) : null,
                                child: Material(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                        // Carte principale
                                                        Container(
                                                                padding: const EdgeInsets.all(defaultPadding),
                                                                decoration: BoxDecoration(
                                                                        color: secondaryColor,
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        border: Border.all(color: borderColor, width: 3)
                                                                ),
                                                                child: Row(
                                                                        children: [
                                                                                SvgPicture.asset(
                                                                                        sensor.svgIcon!,
                                                                                        height: 50,
                                                                                        width: 50,
                                                                                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)
                                                                                ),
                                                                                const SizedBox(width: defaultPadding),
                                                                                Expanded(
                                                                                        child: Text(
                                                                                                sensor.title ?? "Capteur inconnu",
                                                                                                style: Theme.of(context).textTheme.bodyLarge
                                                                                        )
                                                                                )
                                                                        ]
                                                                )
                                                        ),

                                                        // Pastille status en haut à droite
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
                                                                                        color: sensor.powerStatus == null ? Colors.white : Colors.black,
                                                                                        fontSize: 12,
                                                                                        fontWeight: FontWeight.bold
                                                                                )
                                                                        )
                                                                )
                                                        )
                                                ]
                                        )
                                )
                        )
                );
        }

        // Retourne la couleur, bordure et libellé à afficher selon le powerStatus
        (Color, Color, String) getStatusUI(int? status) {
                switch (status) {
                        case 0: return (Colors.grey, Colors.grey, "Inconnu");
                        case 1: return (Colors.green, Colors.green, "Fonctionne");
                        case 2: return (Colors.yellow, Colors.yellow, "Déconnecté");
                        case 3: return (Colors.red, Colors.red, "Erreur");
                        default: return (Colors.black, Colors.black, "Désactivé");
                }
        }

        // Affiche la popup de détails du capteur
        void showSensorPopup(BuildContext context, SensorsData sensor) {
                showDialog(
                        context: context,
                        builder: (context) => SensorDetailsPopup(sensor: sensor)
                );
        }
}