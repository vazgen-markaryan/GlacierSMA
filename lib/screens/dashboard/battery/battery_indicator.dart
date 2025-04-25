/// Affiche l’icône de batterie, son animation et gère l’ouverture du popup.

import 'battery_utils.dart';
import 'battery_popup.dart';
import 'battery_test_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BatteryIndicator extends StatefulWidget {
        final ValueNotifier<double?> voltageNotifier;
        final bool enableTestMode;

        const BatteryIndicator({
                super.key,
                required this.voltageNotifier,

                // Variable pour activer le mode test
                this.enableTestMode = false
        });

        @override
        State<BatteryIndicator> createState() => BatteryIndicatorState();
}

class BatteryIndicatorState extends State<BatteryIndicator>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> pulse;
        bool isPopupVisible = false;

        // Utilitaire de simulation (extrait dans battery_test_mode.dart)
        BatteryTestMode? testMode;

        @override
        void initState() {
                super.initState();

                // Animation de pulsation pour les batteries faibles
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 1000)
                )..repeat(reverse: true);

                pulse = Tween(begin: 1.0, end: 1.2).animate(controller);

                // Si mode test activé, démarrer la simulation
                if (widget.enableTestMode) {
                        testMode = BatteryTestMode(widget.voltageNotifier)
                        ..start();
                }
        }

        @override
        void dispose() {
                controller.dispose();
                testMode?.stop();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return ValueListenableBuilder<double?>(
                        valueListenable: widget.voltageNotifier,
                        builder: (context, voltage, _) {
                                final (percent, iconPath, color) = getBatteryInfo(voltage);
                                final isLow = percent < 0.33;

                                return Builder(
                                        builder: (targetContext) {
                                                return Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
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

        // Ouvre le popup de détails de batterie
        void showPopup(BuildContext targetContext, Color color) {
                if (isPopupVisible) return;
                setState(() => isPopupVisible = true);

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
                                        entry.remove();
                                        setState(() => isPopupVisible = false);
                                },
                                child: Stack(children: [
                                                BatteryPopup(
                                                        voltageNotifier: widget.voltageNotifier,
                                                        color: color,
                                                        position: position
                                                )
                                        ])
                        )
                );

                overlay.insert(entry);
        }
}