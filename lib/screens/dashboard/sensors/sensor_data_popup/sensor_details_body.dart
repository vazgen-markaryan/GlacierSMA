/// Affiche le timestamp mis à jour et la liste des données via ValueListenableBuilder.

import '../sensors_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SensorDetailsBody extends StatelessWidget {
        final SensorsData sensor;
        final String timestamp;

        const SensorDetailsBody({
                super.key,
                required this.sensor,
                required this.timestamp
        });

        @override
        Widget build(BuildContext context) {
                return Flexible(
                        child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Scrollbar(
                                        thumbVisibility: true, radius: const Radius.circular(8), thickness: 6,
                                        child: Padding(
                                                padding: const EdgeInsets.only(right: 20),
                                                child: SingleChildScrollView(
                                                        child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                valueListenable: sensor.dataNotifier,
                                                                builder: (_, data, __) {
                                                                        final items = data.entries.toList();
                                                                        return Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                        Text(
                                                                                                'Mise à jour : $timestamp',
                                                                                                style: const TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic)
                                                                                        ),
                                                                                        const SizedBox(height: 12),
                                                                                        ...items.map((e) => buildRow(e.key, e.value)).toList()
                                                                                ]
                                                                        );
                                                                }
                                                        )
                                                )
                                        )
                                )
                        )
                );
        }

        Widget buildRow(DataMap key, dynamic value) {
                return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                        Row(
                                                children: [
                                                        SvgPicture.asset(key.svgLogo, height: 24, width: 24,
                                                                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(key.name, style: const TextStyle(color: Colors.white70, fontSize: 15))
                                                ]
                                        ),
                                        Flexible(
                                                child: Text(
                                                        value.toString(),
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                        textAlign: TextAlign.right, overflow: TextOverflow.ellipsis
                                                )
                                        )
                                ]
                        )
                );
        }
}