/// Contient toutes les constantes partagées dans l'application.

import 'package:flutter/material.dart';

// Espacement par défaut utilisé dans les mises en page
const defaultPadding = 16.0;

// Couleurs principales de l'application
const primaryColor = Color(0xFF2697FF);
const secondaryColor = Color(0xFF2A2D3E);
const backgroundColor = Color(0xFF212332);

// Type de capteurs disponibles dans le projet
enum SensorType { internal, modbus, stevenson, stevensonStatus }

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

// Messages utilisés pour communiquer avec Arduino
// WARNING: Ces messages doivent rester identiques à ceux utilisés dans le firmware Arduino
const communicationMessageAndroid = "<android>";
const communicationMessagePhoneStart = "\n<phone_start>";
const communicationMessagePhoneEnd = "\n<phone_end>";
const communicationMessageData = "<data>";
const communicationMessageStatus = "<status>";