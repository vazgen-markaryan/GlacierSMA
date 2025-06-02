import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AnomalyRow {
        final String sensorName;
        final String propertyName;
        final String value;
        final String minMax;
        final DateTime timestamp;
        AnomalyRow({
                required this.sensorName,
                required this.propertyName,
                required this.value,
                required this.minMax,
                required this.timestamp
        });
}

class AnomalyBIOSRow extends StatelessWidget {
        final String iconPath;
        final String sensorName;
        final String propertyName;
        final String expected;
        final String actual;
        final DateTime timestamp;

        const AnomalyBIOSRow({
                required this.iconPath,
                required this.sensorName,
                required this.propertyName,
                required this.expected,
                required this.actual,
                required this.timestamp,
                Key? key
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                                children: [
                                        SvgPicture.asset(iconPath, width: 28, height: 28, colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                Text(sensorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                Row(
                                                                        children: [
                                                                                Text(propertyName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                                                                const SizedBox(width: 8),
                                                                                Text(
                                                                                        DateFormat('HH:mm  dd/MM/yyyy').format(timestamp),
                                                                                        style: const TextStyle(color: Colors.white38, fontSize: 12)
                                                                                )
                                                                        ]
                                                                )
                                                        ]
                                                )
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                        Text('Attendu: $expected', style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                                                        Text('Reçu: $actual', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))
                                                ]
                                        )
                                ]
                        )
                );
        }
}