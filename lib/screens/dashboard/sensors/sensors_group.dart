/// sensors_group.dart
/// Affiche un groupe de cartes de capteurs dans une grille responsive,
/// avec un notifier pour rafraîchir automatiquement quand les données/status changent.

import 'sensors_data.dart';
import '../../../constants.dart';
import 'sensor_details_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SensorsGroupNotifier extends ValueNotifier<int> {
        SensorsGroupNotifier(List<SensorsData> sensors) : super(0) {
                // Écouter chaque capteur pour déclencher un rebuild du groupe
                for (var sensor in sensors) {
                        sensor.dataNotifier.addListener(onChange);
                        sensor.powerStatusNotifier.addListener(onChange);
                }
        }
        void onChange() => value++;
}

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
                                // Filtrer les capteurs selon le mode debug ou leur powerStatus
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

        // Construit une carte pour chaque capteur
        Widget buildSensorCard(BuildContext context, SensorsData sensor) {
                final (iconColor, borderColor, statusLabel) = getStatusUI(sensor.powerStatus);

                return SizedBox(
                        width: double.infinity,
                        height: 85,
                        child: GestureDetector(
                                // N’ouvrir la popup que si le capteur a des données
                                onTapDown: (sensor.data.isNotEmpty && sensor.title != "SD Card")
                                        ? (details) {
                                                final tapPosition = details.globalPosition;
                                                showSensorPopup(context, sensor, tapPosition);
                                        }
                                        : null,
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
                                                        // Étiquette de statut en coin
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

        // Affiche la popup depuis le point de clic avec animation de zoom
        void showSensorPopup(BuildContext context, SensorsData sensor, Offset tapPosition) {
                final screenSize = MediaQuery.of(context).size;
                final alignmentX = (tapPosition.dx / screenSize.width) * 2 - 1;
                final alignmentY = (tapPosition.dy / screenSize.height) * 2 - 1;

                showGeneralDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                        transitionBuilder: (_, anim, __, ___) {
                                return Transform.scale(
                                        scale: anim.value,
                                        alignment: Alignment(alignmentX, alignmentY),
                                        child: Opacity(
                                                opacity: anim.value,
                                                child: SensorDetailsPopup(sensor: sensor)
                                        )
                                );
                        }
                );
        }

        // Retourne couleurs et label selon le statut (0–3)
        (Color, Color, String) getStatusUI(int? status) {
                switch (status) {
                        case 0: return (Colors.grey, Colors.grey, "Inconnu");
                        case 1: return (Colors.green, Colors.green, "Fonctionne");
                        case 2: return (Colors.yellow, Colors.yellow, "Déconnecté");
                        case 3: return (Colors.red, Colors.red, "Erreur");
                        default: return (Colors.black, Colors.black, "Désactivé");
                }
        }
}