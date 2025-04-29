/// Affiche un popup animé contenant l’état de la batterie (voltage et pourcentage).
/// Aligné dynamiquement sous l’icône SVG de la batterie avec une petite flèche.

import 'battery_utils.dart';
import 'package:flutter/material.dart';

class BatteryPopup extends StatefulWidget {
        /// Notifier contenant la tension mesurée
        final ValueNotifier<double?> voltageNotifier;

        /// Couleur utilisée pour le texte, la bordure et la flèche
        final Color color;

        /// Position globale de l’icône batterie (coin supérieur gauche)
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
        late final AnimationController controller;
        late final Animation<double> fade;
        late final Animation<double> scale;

        @override
        void initState() {
                super.initState();

                // Démarre l’animation d’apparition (fade + scale)
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();

                fade = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
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
                final screenWidth = MediaQuery.of(context).size.width;

                // Constantes utilisées aussi dans BatteryIndicator
                const iconSize = 35.0;           // Taille de l’icône SVG
                const arrowWidth = 16.0;         // Largeur de la flèche
                const arrowRightOffset = 20.0;   // Distance de la flèche depuis le bord droit du popup

                // Centre horizontal de l’icône SVG
                final iconCenterX = pos.dx + iconSize / 2;

                // Centre visuel de la flèche dans le popup (mesuré depuis le bord droit)
                final arrowCenterInPopup = arrowRightOffset + arrowWidth / 2;

                // Calcul dynamique du positionnement du popup pour que la flèche pointe vers l’icône
                final right = screenWidth - iconCenterX - arrowCenterInPopup;

                return Positioned(
                        top: pos.dy + iconSize + 10, // Affiche le popup sous l’icône
                        right: right,
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
                                                                final (percent, _, __) = getBatteryInfo(voltage);
                                                                return Stack(
                                                                        clipBehavior: Clip.none,
                                                                        children: [
                                                                                // Contenu du popup : voltage et état en pourcentage
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
                                                                                                                voltage != null
                                                                                                                        ? "Voltage : ${voltage.toStringAsFixed(2)} V"
                                                                                                                        : "Voltage : Inconnu",
                                                                                                                style: TextStyle(
                                                                                                                        color: widget.color,
                                                                                                                        fontWeight: FontWeight.bold
                                                                                                                )
                                                                                                        ),
                                                                                                        Text(
                                                                                                                "État : ${(percent * 100).round()}%",
                                                                                                                style: TextStyle(
                                                                                                                        color: widget.color,
                                                                                                                        fontWeight: FontWeight.bold
                                                                                                                )
                                                                                                        )
                                                                                                ]
                                                                                        )
                                                                                ),
                                                                                // Flèche dirigée vers le haut, pointant vers l’icône
                                                                                Positioned(
                                                                                        top: -8,
                                                                                        right: arrowRightOffset,
                                                                                        child: ClipPath(
                                                                                                clipper: TriangleClipper(),
                                                                                                child: Container(
                                                                                                        width: arrowWidth,
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

/// Clip en forme de triangle pour afficher une flèche vers le haut
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