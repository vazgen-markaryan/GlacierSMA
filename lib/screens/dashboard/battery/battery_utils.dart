import 'package:flutter/material.dart';

(double percent, String iconPath, Color color) getBatteryInfo(double? voltage) {
        // Si le voltage est nul, on retourne une valeur par défaut
        final clampedVoltage = voltage?.clamp(11.0, 12.7) ?? 11.0;

        // Calculer le pourcentage de la batterie
        final percent = ((clampedVoltage - 11.0) / (12.7 - 11.0)).clamp(0.0, 1.0);

        if (percent >= 0.66) {
                return (percent, "assets/icons/battery-full.svg", Colors.green);
        }
        else if (percent >= 0.33) {
                return (percent, "assets/icons/battery-mid.svg", Colors.orange);
        }
        else {
                return (percent, "assets/icons/battery-low.svg", Colors.red);
        }
}