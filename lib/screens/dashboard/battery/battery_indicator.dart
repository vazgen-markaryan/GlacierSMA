import 'dart:async';
import 'battery_utils.dart';
import 'battery_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BatteryIndicator extends StatefulWidget {
        final ValueNotifier<double?> voltageNotifier;
        final bool enableTestMode;

        const BatteryIndicator({
                super.key,
                required this.voltageNotifier,
                //  Si on est en mode test, on simule les niveaux de batterie
                this.enableTestMode = false
        });

        @override
        State<BatteryIndicator> createState() => BatteryIndicatorState();
}

class BatteryIndicatorState extends State<BatteryIndicator> with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> pulse;
        bool isPopupVisible = false;

        // Variables pour le mode test
        Timer? testModeTimer;
        int currentTestIndex = 0;

        // Voltages de test pour simuler les états batterie
        final List<double> testVoltages = [12.7, 12.0, 11.2];

        @override
        void initState() {
                super.initState();

                // Animation de pulsation pour les batteries faibles
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 1000)
                )..repeat(reverse: true);

                pulse = Tween(begin: 1.0, end: 1.2).animate(controller);

                // Mode test : alterne les niveaux de batterie toutes les 2 secondes
                if (widget.enableTestMode) {
                        testModeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
                                        widget.voltageNotifier.value = testVoltages[currentTestIndex];
                                        currentTestIndex = (currentTestIndex + 1) % testVoltages.length;
                                }
                        );
                }
        }

        @override
        void dispose() {
                controller.dispose();
                testModeTimer?.cancel();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<double?>(
                        valueListenable: widget.voltageNotifier,
                        builder: (context, voltage, _) {
                                // Récupération du pourcentage, icône et couleur à partir du voltage
                                final (percent, iconPath, color) = getBatteryInfo(voltage);

                                //Variable pour savoir si la batterie est faible
                                final isLow = percent < 0.33;

                                return Builder(
                                        builder: (targetContext) {
                                                return Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                                // Icône principale avec effet de clignotement si batterie faible
                                                                GestureDetector(
                                                                        onTap: () {
                                                                                if (isPopupVisible) return;
                                                                                setState(() => isPopupVisible = true);

                                                                                final renderObject = targetContext.findRenderObject();
                                                                                if (renderObject is! RenderBox) return;

                                                                                final overlay = Overlay.of(context);
                                                                                late final OverlayEntry entry;

                                                                                final box = renderObject;
                                                                                final position = box.localToGlobal(Offset.zero);

                                                                                // Création d’un overlay avec popup
                                                                                entry = OverlayEntry(
                                                                                        builder: (_) => GestureDetector(
                                                                                                behavior: HitTestBehavior.translucent,
                                                                                                onTap: () {
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

                                                                                overlay.insert(entry);
                                                                        },
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

                                                                // Indicateur de "cliquabilité"
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
}