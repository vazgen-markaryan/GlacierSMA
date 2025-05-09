import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/chip_utils.dart';

/// Widget représentant un capteur et son changement ON→OFF ou OFF→ON
class ConfigCustomSensor extends StatelessWidget {
        final String svgIcon, title;
        final String? bus, code, place;
        final bool oldStatus, newStatus;

        const ConfigCustomSensor({
                Key? key,
                required this.svgIcon,
                required this.title,
                this.bus,
                this.code,
                this.place,
                required this.oldStatus,
                required this.newStatus
        }) : super(key: key);

        @override
        Widget build(BuildContext ctx) {
                // Couleur du chip selon le bus
                final busColor = switch (bus?.toLowerCase()) {
                        'modbus' => Colors.teal.shade700,
                        'i2c'    => Colors.blueGrey.shade700,
                        _        => Colors.grey.shade800
                };
                // Préparation des puces (bus, code, place)
                final chips = <ChipData>[];
                if (bus != null) chips.add(ChipData(bus!, busColor));
                if (code != null) chips.add(ChipData(code!, Colors.blueGrey.shade700));
                if (place != null) chips.add(ChipData(place!, Colors.grey.shade800));

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
                                        // Icône + titre + puces
                                        Row(
                                                children: [
                                                        SvgPicture.asset(
                                                                svgIcon,
                                                                height: 24,
                                                                width: 24,
                                                                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                                                        const SizedBox(height: 4),
                                                                        // Affiche toutes les puces en dessous du titre
                                                                        buildChips(chips, fontSize: 10, spacing: 4, runSpacing: 2)
                                                                ]
                                                        )
                                                ]
                                        ),
                                        // Icônes ON → OFF
                                        Row(
                                                children: [
                                                        Icon(oldStatus ? Icons.check_circle : Icons.cancel, color: oldStatus ? Colors.green : Colors.red, size: 16),
                                                        const SizedBox(width: 4),
                                                        const Text('→', style: TextStyle(color: Colors.white)),
                                                        const SizedBox(width: 4),
                                                        Icon(newStatus ? Icons.check_circle : Icons.cancel, color: newStatus ? Colors.green : Colors.red, size: 16)
                                                ]
                                        )
                                ]
                        )
                );
        }
}