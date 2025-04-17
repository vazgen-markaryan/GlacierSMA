import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../constants.dart';
import 'sensors_data.dart';

class SensorDetailsDialog extends StatelessWidget {
        final SensorsData sensor;

        const SensorDetailsDialog({super.key, required this.sensor});

        @override
        Widget build(BuildContext context) {
                return AlertDialog(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                                sensor.title ?? "Détails du capteur",
                                style: const TextStyle(
                                        color: primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold
                                )
                        ),
                        content: SingleChildScrollView(
                                child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                ValueListenableBuilder<DateTime>(
                                                        valueListenable: sensor.lastUpdated,
                                                        builder: (context, timestamp, _) {
                                                                final formatted = DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(timestamp);
                                                                return Text(
                                                                        "Mise à jour $formatted",
                                                                        style: const TextStyle(
                                                                                color: Colors.white54,
                                                                                fontSize: 14,
                                                                                fontStyle: FontStyle.italic
                                                                        )
                                                                );
                                                        }
                                                ),
                                                const SizedBox(height: 8),
                                                ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                        valueListenable: sensor.dataNotifier,
                                                        builder: (context, data, _) {
                                                                return Column(
                                                                        children: data.entries.map((entry) {
                                                                                        final key = entry.key;
                                                                                        final value = entry.value;
                                                                                        return Padding(
                                                                                                padding: const EdgeInsets.only(bottom: 12),
                                                                                                child: Row(
                                                                                                        children: [
                                                                                                                SvgPicture.asset(
                                                                                                                        key.svgLogo,
                                                                                                                        height: 30,
                                                                                                                        width: 30,
                                                                                                                        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                                                                                ),
                                                                                                                const SizedBox(width: 12),
                                                                                                                Expanded(
                                                                                                                        child: Text(
                                                                                                                                "${key.name} :",
                                                                                                                                style: const TextStyle(
                                                                                                                                        color: Colors.white70,
                                                                                                                                        fontSize: 16
                                                                                                                                )
                                                                                                                        )
                                                                                                                ),
                                                                                                                const SizedBox(width: 12),
                                                                                                                Text(
                                                                                                                        value.toString(),
                                                                                                                        style: const TextStyle(
                                                                                                                                color: Colors.white70,
                                                                                                                                fontSize: 16
                                                                                                                        ),
                                                                                                                        textAlign: TextAlign.right
                                                                                                                )
                                                                                                        ]
                                                                                                )
                                                                                        );
                                                                                }
                                                                        ).toList()
                                                                );
                                                        }
                                                )
                                        ]
                                )
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text(
                                                "Fermer",
                                                style: TextStyle(
                                                        color: primaryColor,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold
                                                )
                                        )
                                )
                        ]
                );
        }
}