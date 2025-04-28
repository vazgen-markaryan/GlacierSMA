/// Wrapper qui gère l’animation et le timer, puis compose Header et Body.

import 'dart:async';
import '../sensors_data.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import './sensor_details_body.dart';
import 'package:flutter/material.dart';
import './sensor_details_header.dart';

class SensorDetailsPopup extends StatefulWidget {
        final SensorsData sensor;
        const SensorDetailsPopup({super.key, required this.sensor});

        @override
        State<SensorDetailsPopup> createState() => _SensorDetailsPopupState();
}

class _SensorDetailsPopupState extends State<SensorDetailsPopup>
        with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> scale;
        Timer? timer;

        @override
        void initState() {
                super.initState();
                controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..forward();
                scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
                timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {
                                }
                        ));
        }

        @override
        void dispose() {
                controller.dispose();
                timer?.cancel();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                final ts = DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(DateTime.now());
                return Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: ScaleTransition(
                                scale: scale,
                                child: Center(
                                        child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                        maxWidth: 500,
                                                        maxHeight: MediaQuery.of(context).size.height * 0.75
                                                ),
                                                child: Container(
                                                        decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(16)),
                                                        child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                        // 1) Le header
                                                                        SensorDetailsHeader(
                                                                                title: widget.sensor.title,
                                                                                code: widget.sensor.code,
                                                                                onClose: () => Navigator.of(context).pop()
                                                                        ),
                                                                        // 2) Le body
                                                                        SensorDetailsBody(
                                                                                sensor: widget.sensor,
                                                                                timestamp: ts
                                                                        )
                                                                ]
                                                        )
                                                )
                                        )
                                )
                        )
                );
        }
}