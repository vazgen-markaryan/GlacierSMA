import 'batterry_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BatteryIndicator extends StatefulWidget {
        final ValueNotifier<double?> voltageNotifier;

        const BatteryIndicator({super.key, required this.voltageNotifier});

        @override
        State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> pulse;
        bool isPopupVisible = false;

        @override
        void initState() {
                super.initState();
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
                        valueListenable: widget.voltageNotifier,
                        builder: (context, voltage, _) {
                                if (voltage == null) return const SizedBox.shrink();

                                final percent = ((voltage - 11.0) / (12.7 - 11.0)).clamp(0.0, 1.0);
                                final isLow = percent < 0.33;
                                //final isLow = true;

                                //final fakePercent = 0.9;
                                //final fakePercent = 0.6;
                                //final fakePercent = 0.2;
                                //final (iconPath, color) = _getBatteryVisuals(fakePercent);
                                final (iconPath, color) = _getBatteryVisuals(percent);

                                return Builder(
                                        builder: (targetContext) {
                                                return Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                                GestureDetector(
                                                                        onTap: () {
                                                                                if (isPopupVisible) return;
                                                                                setState(() => isPopupVisible = true);

                                                                                final renderObject = targetContext.findRenderObject();
                                                                                if (renderObject is! RenderBox) return;

                                                                                final overlay = Overlay.of(context);
                                                                                late final OverlayEntry entry;

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
                                                                                                                        voltage: voltage,
                                                                                                                        percent: percent,
                                                                                                                        color: color,
                                                                                                                        onClose: () {
                                                                                                                                entry.remove();
                                                                                                                                setState(() => isPopupVisible = false);
                                                                                                                        },
                                                                                                                        targetContext: targetContext
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
                                                                                        height: 32,
                                                                                        width: 32,
                                                                                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn)
                                                                                )
                                                                        )
                                                                ),
                                                                // Petit indicateur info
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

        (String, Color) _getBatteryVisuals(double percent) {
                if (percent >= 0.66) {
                        return ("assets/icons/battery-full.svg", Colors.green);
                }
                else if (percent >= 0.33) {
                        return ("assets/icons/battery-mid.svg", Colors.orange);
                }
                else {
                        return ("assets/icons/battery-low.svg", Colors.red);
                }
        }
}