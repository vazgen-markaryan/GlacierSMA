/// battery_test_mode.dart
/// Gestion du mode test pour la simulation des niveaux de batterie.

import 'dart:async';
import 'package:flutter/foundation.dart';

class BatteryTestMode {
        final ValueNotifier<double?> voltageNotifier;
        Timer? timer;
        int currentIndex = 0;

        // Voltages de test pour simuler les états batterie
        static const List<double> testVoltages = [12.7, 12.0, 11.2];

        BatteryTestMode(this.voltageNotifier);

        // Démarre la simulation en alternant les tensions toutes les 2 secondes.
        void start() {
                timer = Timer.periodic(
                        const Duration(seconds: 2),
                        (_) {
                                voltageNotifier.value = testVoltages[currentIndex];
                                currentIndex = (currentIndex + 1) % testVoltages.length;
                        }
                );
        }

        // Arrête la simulation.
        void stop() {
                timer?.cancel();
        }
}