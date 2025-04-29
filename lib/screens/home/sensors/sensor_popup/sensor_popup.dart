/// Affiche une popup animée contenant les détails d’un capteur.
/// Le corps de la popup affiche les données et un timestamp mis à jour chaque seconde.

import 'dart:async';
import 'package:intl/intl.dart';
import '../sensors_data.dart';
import './sensor_popup_body.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';

class SensorPopup extends StatefulWidget {
        /// Objet capteur à afficher
        final SensorsData sensor;

        const SensorPopup({super.key, required this.sensor});

        @override
        State<SensorPopup> createState() => SensorPopupState();
}

class SensorPopupState extends State<SensorPopup>
        with SingleTickerProviderStateMixin {
        // Animation d’expansion
        late final AnimationController controller;
        late final Animation<double> scale;

        // Timestamp à afficher dans le body
        late String timestamp;

        // Timer qui rafraîchit le timestamp chaque seconde
        Timer? timer;

        @override
        void initState() {
                super.initState();

                // Démarre l’animation d’ouverture
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();
                scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);

                // Initialise le timestamp et démarre le timer
                timestamp = _now();
                timer = Timer.periodic(
                        const Duration(seconds: 1),
                        (_) => setState(() => timestamp = _now())
                );
        }

        /// Retourne l’instant présent au format lisible
        String _now() =>
        DateFormat("dd-MM-yyyy 'à' HH:mm:ss").format(DateTime.now());

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
                                // Titre dynamique du capteur
                                title: (widget.sensor.title ?? 'Détails du capteur') + (widget.sensor.code != null ? ' (${widget.sensor.code})' : ''),

                                // Corps contenant les données et le timestamp
                                content: SensorPopupBody(
                                        sensor: widget.sensor,
                                        timestamp: timestamp
                                ),

                                // Aucun bouton d’action requis : “X” fourni par CustomPopup
                                actions: const[]
                        )
                );
        }
}