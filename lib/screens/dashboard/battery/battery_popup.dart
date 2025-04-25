/// Affiche un popup stylisé donnant la tension et le pourcentage de batterie.

import 'battery_utils.dart';
import 'package:flutter/material.dart';

class BatteryPopup extends StatefulWidget {

        // Écouteur de tension pour mettre à jour le contenu
        final ValueNotifier<double?> voltageNotifier;

        // Couleur du bord et de la flèche
        final Color color;

        // Position de l'icône batterie pour aligner le popup
        final Offset position;

        const BatteryPopup({
                super.key,
                required this.voltageNotifier,
                required this.color,
                required this.position
        });

        @override
        State<BatteryPopup> createState() => BatteryPopupState();
}

class BatteryPopupState extends State<BatteryPopup> with SingleTickerProviderStateMixin {

        // Contrôleur et animations d'apparition
        late final AnimationController controller;
        late final Animation<double> fade;
        late final Animation<double> scale;

        @override
        void initState() {
                super.initState();
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();

                fade = CurvedAnimation(
                        parent: controller,
                        curve: Curves.easeInOut
                );
                scale = Tween(begin: 0.9, end: 1.0).animate(fade);
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                final pos = widget.position;

                // Place le popup sous l'icône
                return Positioned(
                        top: pos.dy + 40,
                        left: pos.dx - 10,
                        child: FadeTransition(
                                opacity: fade,
                                child: ScaleTransition(
                                        scale: scale,
                                        child: Material(
                                                color: Colors.transparent,
                                                elevation: 6,
                                                shadowColor: Colors.black45,
                                                borderRadius: BorderRadius.circular(12),
                                                child: ValueListenableBuilder<double?>(
                                                        valueListenable: widget.voltageNotifier,
                                                        builder: (context, voltage, _) {
                                                                // Formate la tension et calcule le pourcentage
                                                                final voltageText = voltage?.toStringAsFixed(2) ?? "No Data";
                                                                final (percent, _, __) = getBatteryInfo(voltage);

                                                                return Stack(
                                                                        clipBehavior: Clip.none,
                                                                        children: [
                                                                                // Contenu principal avec bord coloré
                                                                                Container(
                                                                                        padding: const EdgeInsets.all(12),
                                                                                        decoration: BoxDecoration(
                                                                                                color: const Color(0xFF2B2B2B),
                                                                                                borderRadius: BorderRadius.circular(10),
                                                                                                border: Border.all(color: widget.color, width: 2),
                                                                                                boxShadow: const[
                                                                                                        BoxShadow(
                                                                                                                color: Colors.black45,
                                                                                                                blurRadius: 10,
                                                                                                                offset: Offset(0, 4)
                                                                                                        )
                                                                                                ]
                                                                                        ),
                                                                                        child: Column(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                children: [
                                                                                                        Text(
                                                                                                                "Voltage : $voltageText V",
                                                                                                                style: TextStyle(
                                                                                                                        color: widget.color,
                                                                                                                        fontWeight: FontWeight.bold)
                                                                                                        ),
                                                                                                        Text(
                                                                                                                "État : ${(percent * 100).round()}%",
                                                                                                                style: TextStyle(
                                                                                                                        color: widget.color,
                                                                                                                        fontWeight: FontWeight.bold)
                                                                                                        )
                                                                                                ]
                                                                                        )
                                                                                ),

                                                                                // Petite flèche pointant vers l'icône
                                                                                Positioned(
                                                                                        top: -8,
                                                                                        left: 20,
                                                                                        child: ClipPath(
                                                                                                clipper: TriangleClipper(),
                                                                                                child: Container(
                                                                                                        width: 16,
                                                                                                        height: 10,
                                                                                                        color: widget.color
                                                                                                )
                                                                                        )
                                                                                )
                                                                        ]
                                                                );
                                                        }
                                                )
                                        )
                                )
                        )
                );
        }
}

// Clip en forme de triangle pour la flèche du popup
class TriangleClipper extends CustomClipper<Path> {
        @override
        Path getClip(Size size) {
                final path = Path();
                path.moveTo(0, size.height);
                path.lineTo(size.width / 2, 0);
                path.lineTo(size.width, size.height);
                path.close();
                return path;
        }

        @override
        bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}