/// Contient toutes les constantes partagées dans l'application.

import 'package:flutter/material.dart';

// Couleurs principales de l'application
const primaryColor = Color(0xFF2697FF);
const secondaryColor = Color(0xFF2A2D3E);
const backgroundColor = Color(0xFF212332);

// Type de capteurs disponibles dans le projet
enum SensorType {
        internal, modbus
}

// Chemins des icônes représentant les capteurs
const String microchip = "assets/icons/microchip.svg";
const String flashCard = "assets/icons/flash-card.svg";
const String ventilation = "assets/icons/ventilation.svg";
const String luxmetre = "assets/icons/lux.svg";

// Chemins des icônes représentant les données capturées
const String acceleration = "assets/icons/acceleration.svg";
const String altitude = "assets/icons/altitude.svg";
const String brightness = "assets/icons/brightness.svg";
const String gps = "assets/icons/gps.svg";
const String humidity = "assets/icons/humidity.svg";
const String pitchAndRoll = "assets/icons/pitchandroll.svg";
const String pressure = "assets/icons/pressure.svg";
const String temperature = "assets/icons/temperature.svg";
const String range = "assets/icons/range.svg";
const String windDirection = "assets/icons/wind_direction.svg";
const String windSpeed = "assets/icons/wind_speed.svg";
const String windAngle = "assets/icons/wind_angle.svg";
const String satellite = "assets/icons/satellite.svg";

// Messages utilisés pour communiquer avec Arduino
// WARNING: CES MESSAGES DOIVENT RESTER IDENTIQUE À CEUX UTILISÉS DANS LE FIRMWARE ARDUINO
const communicationMessageAndroid = "<android>";
const communicationMessagePhoneStart = "\n<phone_start>";
const communicationMessagePhoneEnd = "\n<phone_end>";
const communicationMessageData = "<data>";
const communicationMessageStatus = "<status>";

// WARNING: LES VALEURS REPRESENTENT DES PLAGES MIN/MAX POUR CHAQUE CAPTEUR SELON LEUR DATASPEC
// Map statique des plages min/max par (sensor, champ)
const Map<String, Map<String, RangeValues>> minMaxRanges = {
        "bme280_status": {
                "bme280_temperature": RangeValues(-40, 85), // Température en °C
                "bme280_pression": RangeValues(30, 110), // Pression en kPa
                "bme280_humidity": RangeValues(0, 100), // Humidité en %
                "bme280_altitude": RangeValues(0, 10000) // Altitude en mètres
        },
        "lsm303_status": {
                "lsm303_roll": RangeValues(-180, 180), // Angle en degrés
                "lsm303_pitch": RangeValues(-180, 180) // Angle en degrés
        },
        "wind_speed_status": {
                "wind_speed": RangeValues(0, 30) // Vitesse du vent en m/s
        },
        "wind_direction_status": {
                "wind_direction_angle": RangeValues(0, 360) // Angle en degrés
        },
        "mb_asl20_status": {
                "mb_asl20": RangeValues(0, 200000) // Luminosité en lux
        },
        "mb_bme280_status": {
                "mb_bme280_temp": RangeValues(-40, 85), // Température en °C
                "mb_bme280_press": RangeValues(30, 110), // Pression en kPa
                "mb_bme280_hum": RangeValues(0, 100) // Humidité en %
        }
};