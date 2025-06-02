import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';

class TestSensorDiffRow extends StatelessWidget {
        final String iconPath;
        final String propertyName;
        final String sensorName;
        final String before;
        final String after;

        const TestSensorDiffRow({
                required this.iconPath,
                required this.propertyName,
                required this.sensorName,
                required this.before,
                required this.after,
                Key? key
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                                children: [
                                        SvgPicture.asset(iconPath, width: 28, height: 28, colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                Text(sensorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                Text(propertyName, style: const TextStyle(color: Colors.white70, fontSize: 13))
                                                        ]
                                                )
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                        Container(
                                                                margin: const EdgeInsets.only(right: 10),
                                                                child: Text('Défaut: $before', style: const TextStyle(color: Colors.white54, fontSize: 13))
                                                        ),
                                                        Container(
                                                                margin: const EdgeInsets.only(right: 10),
                                                                child: Text('Setté: $after', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13))
                                                        )
                                                ]
                                        )
                                ]
                        )
                );
        }
}