import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

class SensorPopup extends StatefulWidget {
        final SensorsData sensor;

        const SensorPopup({super.key, required this.sensor});

        @override
        State<SensorPopup> createState() => SensorPopupState();
}

class SensorPopupState extends State<SensorPopup>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> scale;
        late String timestamp;
        Timer? timer;

        @override
        void initState() {
                super.initState();
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();
                scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);

                timestamp = _now();
                timer = Timer.periodic(
                        const Duration(seconds: 1),
                        (_) => setState(() => timestamp = _now())
                );
        }

        String _now() => DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(DateTime.now());

        @override
        void dispose() {
                controller.dispose();
                timer?.cancel();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return ScaleTransition(
                        scale: scale,
                        child: CustomPopup(
                                title: (widget.sensor.title ?? tr('sensor_details')),
                                content: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Scrollbar(
                                                thumbVisibility: true,
                                                radius: const Radius.circular(8),
                                                thickness: 6,
                                                child: Padding(
                                                        padding: const EdgeInsets.only(right: 12),
                                                        child: SingleChildScrollView(
                                                                child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                        valueListenable: widget.sensor.dataNotifier,
                                                                        builder: (_, data, __) {
                                                                                final items = data.entries.toList();
                                                                                return Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                                Text(
                                                                                                        tr('updated_at', args: [timestamp]),
                                                                                                        style: const TextStyle(
                                                                                                                color: Colors.white54,
                                                                                                                fontSize: 16,
                                                                                                                fontStyle: FontStyle.italic
                                                                                                        )
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
                                ),
                                actions: const[]
                        )
                );
        }

        Widget buildRow(DataMap key, dynamic value) {
                // Affiche la valeur brute +, si Iridium, ajoute la traduction (0–5 → Mauvais, OK…)
                String display = value.toString();
                if (key.header.toLowerCase() == 'iridium_signal_quality') {
                        final q = int.tryParse(display) ?? -1;
                        final txt = getIridiumSvgLogoAndColor(q)['value'] as String;
                        display = '$display ($txt)';
                }

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
                                        Row(
                                                children: [
                                                        SvgPicture.asset(
                                                                key.svgLogo,
                                                                height: 24,
                                                                width: 24,
                                                                colorFilter: const ColorFilter.mode(
                                                                        Colors.white70, BlendMode.srcIn
                                                                )
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                                key.name,
                                                                style: const TextStyle(color: Colors.white70, fontSize: 15)
                                                        )
                                                ]
                                        ),
                                        Flexible(
                                                child: Text(
                                                        display,
                                                        style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold
                                                        ),
                                                        textAlign: TextAlign.right,
                                                        overflow: TextOverflow.ellipsis
                                                )
                                        )
                                ]
                        )
                );
        }
}
