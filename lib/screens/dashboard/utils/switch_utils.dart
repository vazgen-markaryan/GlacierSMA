/// switch_utils.dart
/// Contient des utilitaires pour :
///  Obtenir l’unité à afficher selon l’en-tête de donnée Arduino
///  Traduire la direction du vent codée (0–16) en texte
///  Convertir le code d’état de l’antenne GPS en valeur lisible

// WARNING: NE JAMAIS CHANGER CES CAS S’ILS NE SONT PAS CHANGÉS DANS LE CODE ARDUINO
String getUnitForHeader(String header) {
        switch (header.toLowerCase()) {
                case "bme280_temperature":
                case "mb_bme280_temp":
                case "steve_bme280_temp":
                        return " °C";
                case "bme280_pression":
                case "mb_bme280_press":
                case "steve_bme280_press":
                        return " kPa";
                case "bme280_humidity":
                case "mb_bme280_hum":
                case "steve_bme280_hum":
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
                case "steve_veml7700":
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

// Traduit le code d’état de l’antenne GPS en valeur lisible.
String getGPSAntennaRealValue(int value) {
        switch (value) {
                case 0: return "Inconnu";
                case 1: return "Externe";
                case 2: return "Interne";
                case 3: return "Court-circuit d’antenne externe";
                default: return "Inconnu";
        }
}