/// Définit le modèle `DataMap` (clé de donnée) et `SensorsData` (état et valeurs),
/// ainsi que la liste par défaut de tous les capteurs et la fonction d’accès.

import '../utils/constants.dart';
import 'package:flutter/material.dart';

class DataMap {
        final String name, header, svgLogo;

        const DataMap({
                required this.name,
                required this.header,
                required this.svgLogo
        });

        @override
        bool operator==(Object other) =>
        identical(this, other) ||
                other is DataMap &&
                        runtimeType == other.runtimeType &&
                        name == other.name &&
                        header == other.header &&
                        svgLogo == other.svgLogo;

        @override
        int get hashCode => name.hashCode ^ header.hashCode ^ svgLogo.hashCode;
}

class SensorsData {
        String? svgIcon, title, header, temp, pres, hum, antenna, code;
        Color? color;

        // Notifiers pour valeurs et statut (powerStatus)
        final ValueNotifier<Map<DataMap, dynamic>> dataNotifier;
        final ValueNotifier<int?> powerStatusNotifier;

        int? get powerStatus => powerStatusNotifier.value;
        set powerStatus(int? value) => powerStatusNotifier.value = value;

        SensorsData({
                this.svgIcon, this.title, this.color,
                this.header, this.temp, this.pres,
                this.hum, this.antenna, this.code,
                required Map<DataMap, dynamic> data,
                int? powerStatus
        }) : dataNotifier = ValueNotifier(data),
                powerStatusNotifier = ValueNotifier(powerStatus);

        Map<DataMap, dynamic> get data => dataNotifier.value;

        // Méthode utilitaire pour changer une valeur et notifier
        void updateData(DataMap key, dynamic newValue) {
                final updated = Map<DataMap, dynamic>.from(dataNotifier.value);
                updated[key] = newValue;
                dataNotifier.value = updated;
        }
}

// Fonction d’accès à la liste de capteurs selon le type
List<SensorsData> getSensors(SensorType type) {
        switch (type) {
                case SensorType.internal:
                        return internalSensors;
                case SensorType.modbus:
                        return modBusSensors;
                case SensorType.stevenson:
                        return stevensonSensors;
                case SensorType.stevensonStatus:
                        return stevensonStatus;
        }
}

List<SensorsData> internalSensors = [
        SensorsData(
                title: "Thermo-Hygro-Baromètre",
                header: "bme280_status",
                code: "BME280",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "bme280_temperature", svgLogo: temperature) : "Placeholder par défaut",
                        DataMap(name: "Pression", header: "bme280_pression", svgLogo: pressure) : "Placeholder par défaut",
                        DataMap(name: "Altitude", header: "bme280_altitude", svgLogo: altitude) : "Placeholder par défaut",
                        DataMap(name: "Humidité", header: "bme280_humidity", svgLogo: humidity) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "Accéléromètre",
                header: "lsm303_status",
                code: "LSM303",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Accélération X", header: "lsm303_accel_x", svgLogo: acceleration) : "Placeholder par défaut",
                        DataMap(name: "Accélération Y", header: "lsm303_accel_y", svgLogo: acceleration) : "Placeholder par défaut",
                        DataMap(name: "Accélération Z", header: "lsm303_accel_z", svgLogo: acceleration) : "Placeholder par défaut",
                        DataMap(name: "Roll", header: "lsm303_roll", svgLogo: pitchAndRoll) : "Placeholder par défaut",
                        DataMap(name: "Pitch", header: "lsm303_pitch", svgLogo: pitchAndRoll) : "Placeholder par défaut",
                        DataMap(name: "Accélération Range", header: "lsm303_accel_range", svgLogo: range) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "GPS",
                header: "gps_status",
                antenna: "gps_antenna_status",
                svgIcon: gps,
                data: {
                        DataMap(name: "Latitude", header: "gps_latitude", svgLogo: gps) : "Placeholder par défaut",
                        DataMap(name: "Longitude", header: "gps_longitude", svgLogo: gps) : "Placeholder par défaut",
                        DataMap(name: "Satelites", header: "gps_satelites", svgLogo: gps) : "Placeholder par défaut",
                        DataMap(name: "HDOP", header: "gps_hdop", svgLogo: gps) : "Placeholder par défaut",
                        DataMap(name: "Antenne", header: "gps_antenna_status", svgLogo: gps) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "SD Card",
                header: "sdcard",
                svgIcon: flashCard,
                data: {} // Doit être vide
        )
];

List<SensorsData> modBusSensors = [
        SensorsData(
                title: "Anémomètre",
                header: "wind_speed_status",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "Vitesse", header: "wind_speed", svgLogo: windSpeed) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "Girouette",
                header: "wind_direction_status",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "Angle", header: "wind_direction_angle", svgLogo: windAngle) : "Placeholder par défaut",
                        DataMap(name: "Orientation", header: "wind_direction_facing", svgLogo: windDirection) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "Luxmètre",
                header: "mb_asl20_status",
                code: "ASL20",
                svgIcon: luxmetre,
                data: {
                        DataMap(name: "Luminosité", header: "mb_asl20", svgLogo: luxmetre) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "Thermo-Hygro-Baromètre",
                header: "mb_bme280_status",
                code: "BME280",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "mb_bme280_temp", svgLogo: temperature) : "Placeholder par défaut",
                        DataMap(name: "Pression", header: "mb_bme280_press", svgLogo: pressure) : "Placeholder par défaut",
                        DataMap(name: "Humidité", header: "mb_bme280_hum", svgLogo: humidity) : "Placeholder par défaut"
                }
        )
];

List<SensorsData> stevensonSensors = [
        SensorsData(
                title: "Thermo-Hygro-Baromètre",
                temp: "steve_bme280_temp_status",
                pres: "steve_bme280_pres_status",
                hum: "steve_bme280_hum_status",
                code: "BME280",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "steve_bme280_temp", svgLogo: temperature) : "Placeholder par défaut",
                        DataMap(name: "Pression", header: "steve_bme280_press", svgLogo: pressure) : "Placeholder par défaut",
                        DataMap(name: "Humidité", header: "steve_bme280_hum", svgLogo: humidity) : "Placeholder par défaut"
                }
        ),

        SensorsData(
                title: "Luxmètre",
                header: "steve_veml7700_status",
                code: "VEML7700",
                svgIcon: luxmetre,
                data: {
                        DataMap(name: "Luminosité", header: "steve_veml7700", svgLogo: luxmetre) : "Placeholder par défaut"
                }
        )
];

List<SensorsData> stevensonStatus = [
        SensorsData(
                title: "Stevenson",
                header: "steve_status",
                svgIcon: microchip,
                data: {} // Doit être vide
        )
];