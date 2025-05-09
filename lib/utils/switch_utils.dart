import 'dart:ui';

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

// Convertit le code de direction du vent (0–16) en texte français.
String getWindDirectionFacing(int value) {
        switch (value) {
                case 0:  return "Nord";
                case 1:  return "Nord-nord-est";
                case 2:  return "Nord-est";
                case 3:  return "Est-nord-est";
                case 4:  return "Est";
                case 5:  return "Est-sud-est";
                case 6:  return "Sud-est";
                case 7:  return "Sud-sud-est";
                case 8:  return "Sud";
                case 9:  return "Sud-sud-ouest";
                case 10: return "Sud-ouest";
                case 11: return "Ouest-sud-ouest";
                case 12: return "Ouest";
                case 13: return "Ouest-nord-ouest";
                case 14: return "Nord-ouest";
                case 15: return "Nord-nord-ouest";
                case 16: return "Nord";
                default: return "Inconnu";
        }
}

/// Retourne le chemin du fichier SVG à utiliser pour Iridium en fonction de la qualité du signal (0 = mauvais → mauvais icône),
/// Retourne aussi la couleur à appliquer au SVG et la valeur à afficher.
Map<String, dynamic> getIridiumSvgLogoAndColor(int quality) {
        switch (quality) {
                case 5:
                        return {
                                'icon':  'assets/icons/satellite_excellent.svg',
                                'color': const Color(0xFF00FF00), // Vert,
                                'value': 'Excellent'
                        };
                case 4:
                        return {
                                'icon':  'assets/icons/satellite_very_good.svg',
                                'color': const Color(0xFF7FFF00), // Vert clair
                                'value': 'Très bon'
                        };
                case 3:
                case 2:
                        return {
                                'icon':  'assets/icons/satellite_ok.svg',
                                'color': const Color(0xFFFFA500), // Orange
                                'value': 'OK'
                        };
                case 1:
                case 0:
                        return {
                                'icon': 'assets/icons/satellite_bad.svg',
                                'color': const Color(0xFFFF0000), // Rouge
                                'value': 'Mauvais'
                        };
                default:
                return {
                        'icon':  'assets/icons/satellite_error.svg',
                        'color': const Color(0xFF000000), // Noir
                        'value': 'Erreur'
                };
        }
}