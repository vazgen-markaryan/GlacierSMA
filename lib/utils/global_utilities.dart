import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Contient des utilitaires pour :
///  Obtenir l’unité à afficher selon l’en-tête de donnée Arduino
///  Choisir l’icône SVG Iridium selon la qualité du signal

// WARNING: NE JAMAIS CHANGER CES CAS S’ILS NE SONT PAS CHANGÉS DANS LE CODE ARDUINO
String getUnitForHeader(String header) {
        switch (header.toLowerCase()) {
                case "bme280_temperature":
                case "mb_bme280_temp":
                        return " °C";
                case "bme280_pression":
                case "mb_bme280_press":
                        return " kPa";
                case "bme280_humidity":
                case "mb_bme280_hum":
                        return " %";
                case "bme280_altitude":
                        return " m";
                case "lsm303_accel_x":
                case "lsm303_accel_y":
                case "lsm303_accel_z":
                        return " m/s²";
                case "lsm303_roll":
                case "lsm303_pitch":
                        return " °";
                case "lsm303_accel_range":
                        return " g";
                case "wind_speed":
                        return " m/s";
                case "wind_direction_angle":
                        return " °";
                case "mb_asl20":
                        return " lux";
                default: return "";
        }
}

/// Retourne le chemin du fichier SVG à utiliser pour Iridium en fonction de la qualité du signal (0 = mauvais → mauvais icône),
/// Retourne aussi la couleur à appliquer au SVG et la valeur à afficher.
Map<String, dynamic> getIridiumSvgLogoAndColor(int quality) {
        switch (quality) {
                case 5:
                        return {
                                'icon':  'assets/icons/satellite_excellent.svg',
                                'color': const Color(0xFF00FF00), // Vert
                                'value': tr('global_utilities.iridium.quality.excellent')
                        };
                case 4:
                        return {
                                'icon':  'assets/icons/satellite_very_good.svg',
                                'color': const Color(0xFF7FFF00), // Vert clair
                                'value': tr('global_utilities.iridium.quality.very_good')
                        };
                case 3:
                case 2:
                        return {
                                'icon':  'assets/icons/satellite_ok.svg',
                                'color': const Color(0xFFFFA500), // Orange
                                'value': tr('global_utilities.iridium.quality.good')
                        };
                case 1:
                case 0:
                        return {
                                'icon':  'assets/icons/satellite_bad.svg',
                                'color': const Color(0xFFFF0000), // Rouge
                                'value': tr('global_utilities.iridium.quality.bad')
                        };
                default:
                return {
                        'icon':  'assets/icons/satellite_error.svg',
                        'color': const Color(0xFF000000), // Noir
                        'value': tr('global_utilities.iridium.quality.error')
                };
        }
}