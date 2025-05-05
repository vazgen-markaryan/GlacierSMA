/// Affiche l’icône de batterie avec une animation de pulsation si niveau faible.
/// Gère un mode test pour simuler des tensions, et ouvre un popup indiquant le voltage et le pourcentage.

import 'battery_utils.dart';
import 'battery_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BatteryIndicator extends StatefulWidget {
        /// Notifier qui contient la tension actuelle de la batterie
        final ValueNotifier<double?> voltageNotifier;

        /// Active un mode test qui simule des tensions changeantes
        final bool enableTestMode;

        const BatteryIndicator({
                super.key,
                required this.voltageNotifier,
                this.enableTestMode = false
        });

        @override
        State<BatteryIndicator> createState() => BatteryIndicatorState();
}

class BatteryIndicatorState extends State<BatteryIndicator>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> pulse;

        /// Empêche l'ouverture de plusieurs popups simultanément
        bool isPopupVisible = false;

        @override
        void initState() {
                super.initState();

                // Animation de pulsation pour le cas où la batterie est faible
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 1000)
                )..repeat(reverse: true);

                pulse = Tween(begin: 1.0, end: 1.2).animate(controller);
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<double?>(
                        // Reconstruit l’icône à chaque nouvelle valeur de tension
                        valueListenable: widget.voltageNotifier,
                        builder: (context, voltage, _) {
                                final (percent, iconPath, color) = getBatteryInfo(voltage);
                                final isLow = percent < 0.33;

                                return Builder(
                                        builder: (targetContext) {
                                                return Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                                // Icône SVG, cliquable pour ouvrir le popup
                                                                GestureDetector(
                                                                        onTap: () => showPopup(targetContext, color),
                                                                        child: AnimatedBuilder(
                                                                                animation: pulse,
                                                                                builder: (_, child) => Transform.scale(
                                                                                        scale: isLow ? pulse.value : 1.0,
                                                                                        child: child
                                                                                ),
                                                                                child: SvgPicture.asset(
                                                                                        iconPath,
                                                                                        height: 35,
                                                                                        width: 35,
                                                                                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn)
                                                                                )
                                                                        )
                                                                ),
                                                                // Petite icône "touch" pour indiquer que c'est cliquable
                                                                Positioned(
                                                                        top: -3,
                                                                        right: -3,
                                                                        child: Container(
                                                                                padding: const EdgeInsets.all(2),
                                                                                decoration: const BoxDecoration(
                                                                                        shape: BoxShape.circle,
                                                                                        color: Colors.white
                                                                                ),
                                                                                child: const Icon(
                                                                                        Icons.touch_app,
                                                                                        size: 14,
                                                                                        color: Colors.black
                                                                                )
                                                                        )
                                                                )
                                                        ]
                                                );
                                        }
                                );
                        }
                );
        }

        /// Ouvre un [OverlayEntry] contenant [BatteryPopup] positionné sous l’icône
        void showPopup(BuildContext targetContext, Color color) {
                if (isPopupVisible) return;
                setState(() => isPopupVisible = true);

                // Calcule la position globale du widget cliqué
                final renderObject = targetContext.findRenderObject();
                if (renderObject is! RenderBox) return;
                final box = renderObject;
                final position = box.localToGlobal(Offset.zero);

                final overlay = Overlay.of(context);
                late final OverlayEntry entry;

                entry = OverlayEntry(
                        builder: (_) => GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                        // Ferme le popup au clic en dehors
                                        entry.remove();
                                        setState(() => isPopupVisible = false);
                                },
                                child: Stack(
                                        children: [
                                                BatteryPopup(
                                                        voltageNotifier: widget.voltageNotifier,
                                                        color: color,
                                                        position: position
                                                )
                                        ]
                                )
                        )
                );

                // Insère le popup dans l’Overlay
                overlay.insert(entry);
        }
}