/// sensor_details_popup.dart
/// Affiche une popup stylisée avec animation pour voir les détails d’un capteur.
/// Icônes, noms et valeurs dynamiques sont mises à jour via un ValueNotifier.

import 'sensors_data.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SensorDetailsPopup extends StatefulWidget {
        final SensorsData sensor;

        const SensorDetailsPopup({super.key, required this.sensor});

        @override
        State<SensorDetailsPopup> createState() => SensorDetailsPopupState();
}

class SensorDetailsPopupState extends State<SensorDetailsPopup>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> scale;

        @override
        void initState() {
                super.initState();
                // Animation d’apparition avec effet easeOutBack
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();
                scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: ScaleTransition(
                                scale: scale,
                                child: Center(
                                        child: ConstrainedBox(
                                                // Limiter largeur et hauteur max de la popup
                                                constraints: BoxConstraints(
                                                        maxWidth: 500,
                                                        maxHeight: MediaQuery.of(context).size.height * 0.75
                                                ),
                                                child: Container(
                                                        decoration: BoxDecoration(
                                                                color: secondaryColor,
                                                                borderRadius: BorderRadius.circular(16)
                                                        ),
                                                        child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                        // Header stylisé avec titre et bouton de fermeture
                                                                        Container(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                                                decoration: const BoxDecoration(
                                                                                        color: Color(
                                                                                                0xFF403B3B),
                                                                                        borderRadius: BorderRadius.only(
                                                                                                topLeft: Radius.circular(16),
                                                                                                topRight: Radius.circular(16)
                                                                                        )
                                                                                ),
                                                                                child: Row(
                                                                                        children: [
                                                                                                Expanded(
                                                                                                        child: Text(

                                                                                                                (widget.sensor.title ?? "Détails du capteur") + (widget.sensor.code != null ? " (${widget.sensor.code})" : ""),
                                                                                                                style: const TextStyle(
                                                                                                                        color: primaryColor,
                                                                                                                        fontSize: 20,
                                                                                                                        fontWeight: FontWeight.bold
                                                                                                                )
                                                                                                        )
                                                                                                ),
                                                                                                GestureDetector(
                                                                                                        onTap: () => Navigator.of(context).pop(),
                                                                                                        child: const Icon(Icons.close, color: Colors.red, size: 30)
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        ),

                                                                        // Corps : timestamp et liste des valeurs
                                                                        Flexible(
                                                                                child: Padding(
                                                                                        padding: const EdgeInsets.all(20),
                                                                                        child: Scrollbar(
                                                                                                thumbVisibility: true,
                                                                                                radius: const Radius.circular(8),
                                                                                                thickness: 6,
                                                                                                child: Padding(
                                                                                                        padding: const EdgeInsets.only(right: 20),
                                                                                                        child: SingleChildScrollView(
                                                                                                                child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                                                                        valueListenable: widget.sensor.dataNotifier,
                                                                                                                        builder: (context, data, _) {
                                                                                                                                final items = data.entries.toList();

                                                                                                                                return Column(
                                                                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                                        children: [
                                                                                                                                                // Affiche la date/heure de mise à jour
                                                                                                                                                Text(
                                                                                                                                                        "Mise à jour : ${DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(DateTime.now())}",
                                                                                                                                                        style: const TextStyle(
                                                                                                                                                                color: Colors.white54,
                                                                                                                                                                fontSize: 16,
                                                                                                                                                                fontStyle: FontStyle.italic
                                                                                                                                                        )
                                                                                                                                                ),
                                                                                                                                                const SizedBox(height: 12),
                                                                                                                                                // Affichage de chaque entrée de donnée
                                                                                                                                                ...items.map(
                                                                                                                                                        (entry) {
                                                                                                                                                                final key = entry.key;
                                                                                                                                                                final value = entry.value;
                                                                                                                                                                return Container(
                                                                                                                                                                        margin: const EdgeInsets.only(bottom: 10),
                                                                                                                                                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                                                                                                                        decoration: BoxDecoration(
                                                                                                                                                                                color: Colors.white10,
                                                                                                                                                                                borderRadius: BorderRadius.circular(8)
                                                                                                                                                                        ),
                                                                                                                                                                        child: Row(
                                                                                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                                                                                children: [
                                                                                                                                                                                        Row(
                                                                                                                                                                                                children: [
                                                                                                                                                                                                        // Icône SVG de la donnée
                                                                                                                                                                                                        SvgPicture.asset(
                                                                                                                                                                                                                key.svgLogo,
                                                                                                                                                                                                                height: 24,
                                                                                                                                                                                                                width: 24,
                                                                                                                                                                                                                colorFilter: const ColorFilter.mode(
                                                                                                                                                                                                                        Colors.white70,
                                                                                                                                                                                                                        BlendMode.srcIn
                                                                                                                                                                                                                )
                                                                                                                                                                                                        ),
                                                                                                                                                                                                        const SizedBox(width: 8),
                                                                                                                                                                                                        // Nom de la donnée
                                                                                                                                                                                                        Text(
                                                                                                                                                                                                                key.name,
                                                                                                                                                                                                                style: const TextStyle(
                                                                                                                                                                                                                        color: Colors.white70,
                                                                                                                                                                                                                        fontSize: 15
                                                                                                                                                                                                                )
                                                                                                                                                                                                        )
                                                                                                                                                                                                ]
                                                                                                                                                                                        ),
                                                                                                                                                                                        // Valeur
                                                                                                                                                                                        Flexible(
                                                                                                                                                                                                child: Text(
                                                                                                                                                                                                        value.toString(),
                                                                                                                                                                                                        style: const TextStyle(
                                                                                                                                                                                                                color: Colors.white,
                                                                                                                                                                                                                fontWeight: FontWeight.bold
                                                                                                                                                                                                        ),
                                                                                                                                                                                                        textAlign: TextAlign.right,
                                                                                                                                                                                                        overflow: TextOverflow.ellipsis
                                                                                                                                                                                                )
                                                                                                                                                                                        )
                                                                                                                                                                                ]
                                                                                                                                                                        )
                                                                                                                                                                );
                                                                                                                                                        }
                                                                                                                                                ).toList()
                                                                                                                                        ]
                                                                                                                                );
                                                                                                                        }
                                                                                                                )
                                                                                                        )
                                                                                                )
                                                                                        )
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                )
                                        )
                                )
                        )
                );
        }
}