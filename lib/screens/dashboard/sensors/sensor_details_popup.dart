import 'sensors_data.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Affiche une popup contenant les détails d'un capteur (valeurs, icônes, timestamp)
// Apparition avec animation, fermeture par bouton ou clic à l'extérieur
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

                // Animation scale pour faire apparaître la popup avec un effet doux
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
                return GestureDetector(
                        // Ferme la popup si clic à l'extérieur
                        onTap: () => Navigator.of(context).pop(),
                        child: Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                                child: GestureDetector(
                                        // Empêche la fermeture si clic sur le contenu de la popup
                                        onTap: () {},
                                        child: ScaleTransition(
                                                scale: scale,
                                                child: Center(
                                                        child: Container(
                                                                // Taille max de la popup (responsive)
                                                                constraints: BoxConstraints(
                                                                        maxWidth: 500,
                                                                        maxHeight: MediaQuery.of(context).size.height * 0.75
                                                                ),
                                                                decoration: BoxDecoration(
                                                                        color: secondaryColor,
                                                                        borderRadius: BorderRadius.circular(16)
                                                                ),
                                                                padding: const EdgeInsets.all(20),
                                                                child: Scrollbar(
                                                                        thumbVisibility: true, // Toujours afficher le scroll
                                                                        radius: const Radius.circular(8),
                                                                        thickness: 6,
                                                                        child: Padding(
                                                                                // Décale le contenu vers la gauche pour éviter chevauchement avec le scroll
                                                                                padding: const EdgeInsets.only(right: 20.0),
                                                                                child: SingleChildScrollView(
                                                                                        child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                                                valueListenable: widget.sensor.dataNotifier,
                                                                                                builder: (context, data, _) {
                                                                                                        final items = data.entries.toList();

                                                                                                        return Column(
                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                children: [
                                                                                                                        // Titre du capteur
                                                                                                                        Text(
                                                                                                                                widget.sensor.title ?? "Détails du capteur",
                                                                                                                                style: const TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                                                                                                        ),

                                                                                                                        const SizedBox(height: 12),

                                                                                                                        // Timestamp de dernière mise à jour
                                                                                                                        Text(
                                                                                                                                "Mise à jour : ${DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(DateTime.now())}",
                                                                                                                                style: const TextStyle(color: Colors.white54, fontSize: 14, fontStyle: FontStyle.italic)
                                                                                                                        ),

                                                                                                                        const SizedBox(height: 12),

                                                                                                                        // Affichage des paires clé-valeur
                                                                                                                        ...items.map(
                                                                                                                                (entry) {
                                                                                                                                        final key = entry.key;
                                                                                                                                        final value = entry.value;

                                                                                                                                        return Container(
                                                                                                                                                margin: const EdgeInsets.only(bottom: 10),
                                                                                                                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                                                                                                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                                                                                                                                child: Row(
                                                                                                                                                        mainAxisAlignment:
                                                                                                                                                        MainAxisAlignment.spaceBetween,
                                                                                                                                                        children: [
                                                                                                                                                                // Icône et nom de la donnée
                                                                                                                                                                Row(
                                                                                                                                                                        children: [
                                                                                                                                                                                SvgPicture.asset(
                                                                                                                                                                                        key.svgLogo,
                                                                                                                                                                                        height: 24,
                                                                                                                                                                                        width: 24,
                                                                                                                                                                                        colorFilter:
                                                                                                                                                                                        const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                                                                                                                                                ),

                                                                                                                                                                                const SizedBox(width: 8),

                                                                                                                                                                                Text(key.name, style: const TextStyle(color: Colors.white70, fontSize: 15))
                                                                                                                                                                        ]
                                                                                                                                                                ),

                                                                                                                                                                // Valeur de la donnée
                                                                                                                                                                Flexible(
                                                                                                                                                                        child: Text(value.toString(),
                                                                                                                                                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                                                                                                                                                textAlign: TextAlign.right,
                                                                                                                                                                                overflow: TextOverflow.ellipsis
                                                                                                                                                                        )
                                                                                                                                                                )
                                                                                                                                                        ]
                                                                                                                                                )
                                                                                                                                        );
                                                                                                                                }
                                                                                                                        ),

                                                                                                                        const SizedBox(height: 16),

                                                                                                                        // Bouton "Fermer" en bas à droite
                                                                                                                        Align(
                                                                                                                                alignment: Alignment.centerRight,
                                                                                                                                child: TextButton(
                                                                                                                                        onPressed: () =>
                                                                                                                                        Navigator.of(context).pop(),
                                                                                                                                        child: const Text("Fermer", style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold))
                                                                                                                                )
                                                                                                                        )
                                                                                                                ]
                                                                                                        );
                                                                                                }
                                                                                        )
                                                                                )
                                                                        )
                                                                )
                                                        )
                                                )
                                        )
                                )
                        )
                );
        }
}