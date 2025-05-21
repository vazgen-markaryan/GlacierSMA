import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Contient des utilitaires pour :
///  Obtenir l’unité à afficher selon l’en-tête de donnée Arduino
///  Traduire la direction du vent codée (0–16) en texte
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

// Convertit le code de direction du vent (0–16) en texte localisé.
String getWindDirectionFacing(int value) {
        switch (value) {
                case 0:  return tr('switch_utils.wind_direction.north');
                case 1:  return tr('switch_utils.wind_direction.north_northeast');
                case 2:  return tr('switch_utils.wind_direction.northeast');
                case 3:  return tr('switch_utils.wind_direction.east_northeast');
                case 4:  return tr('switch_utils.wind_direction.east');
                case 5:  return tr('switch_utils.wind_direction.east_southeast');
                case 6:  return tr('switch_utils.wind_direction.southeast');
                case 7:  return tr('switch_utils.wind_direction.south_southeast');
                case 8:  return tr('switch_utils.wind_direction.south');
                case 9:  return tr('switch_utils.wind_direction.south_southwest');
                case 10: return tr('switch_utils.wind_direction.southwest');
                case 11: return tr('switch_utils.wind_direction.west_southwest');
                case 12: return tr('switch_utils.wind_direction.west');
                case 13: return tr('switch_utils.wind_direction.west_northwest');
                case 14: return tr('switch_utils.wind_direction.northwest');
                case 15: return tr('switch_utils.wind_direction.north_northwest');
                case 16: return tr('switch_utils.wind_direction.north');
                default: return tr('switch_utils.wind_direction.unknown');
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
                                'value': tr('switch_utils.iridium.quality.excellent')
                        };
                case 4:
                        return {
                                'icon':  'assets/icons/satellite_very_good.svg',
                                'color': const Color(0xFF7FFF00), // Vert clair
                                'value': tr('switch_utils.iridium.quality.very_good')
                        };
                case 3:
                case 2:
                        return {
                                'icon':  'assets/icons/satellite_ok.svg',
                                'color': const Color(0xFFFFA500), // Orange
                                'value': tr('switch_utils.iridium.quality.good')
                        };
                case 1:
                case 0:
                        return {
                                'icon':  'assets/icons/satellite_bad.svg',
                                'color': const Color(0xFFFF0000), // Rouge
                                'value': tr('switch_utils.iridium.quality.bad')
                        };
                default:
                return {
                        'icon':  'assets/icons/satellite_error.svg',
                        'color': const Color(0xFF000000), // Noir
                        'value': tr('switch_utils.iridium.quality.error')
                };
        }
}