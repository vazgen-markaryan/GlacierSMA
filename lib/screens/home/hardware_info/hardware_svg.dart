import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rev_glacier_sma_mobile/screens/home/hardware_info/hardware_popup.dart';

class HardwareSVG extends StatelessWidget {
        /// Notifier qui contient la tension actuelle de la batterie
        final ValueNotifier<double?> voltageNotifier;

        /// Active un mode test qui simule des tensions changeantes
        final bool enableTestMode;

        /// Notifier pour les données RAM, utilisé dans le popup
        final ValueNotifier<Map<String, double?>> ramNotifier;

        const HardwareSVG({
                super.key,
                required this.voltageNotifier,
                required this.ramNotifier,
                this.enableTestMode = false
        });

        @override
        Widget build(BuildContext context) {
                return Builder(
                        builder: (targetContext) {
                                return GestureDetector(
                                        onTap: () {
                                                HardwarePopup.show(
                                                        context: context,
                                                        iconKey: targetContext,
                                                        voltageNotifier: voltageNotifier,
                                                        ramNotifier: ramNotifier
                                                );
                                        },
                                        child: SvgPicture.asset(
                                                "assets/icons/hardware.svg",
                                                height: 35,
                                                width: 35,
                                                colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn)
                                        )
                                );
                        }
                );
        }
}