import '../../../constants.dart';
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
        String? svgIcon, title, header, temp, pres, hum, antenna;
        int? powerStatus;
        Color? color;

        final ValueNotifier<Map<DataMap, dynamic>> dataNotifier;

        Map<DataMap, dynamic> get data => dataNotifier.value;

        SensorsData({
                this.svgIcon, this.title, this.powerStatus, this.color,
                this.header, this.temp, this.pres, this.hum, this.antenna,
                required Map<DataMap, dynamic> data
        }) : dataNotifier = ValueNotifier(data);

        void updateData(DataMap key, dynamic newValue) {
                final updated = Map<DataMap, dynamic>.from(dataNotifier.value);
                updated[key] = newValue;
                dataNotifier.value = updated;
        }
}

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
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "bme280_temperature", svgLogo: temperature) : "default_value",
                        DataMap(name: "Pression", header: "bme280_pression", svgLogo: pressure) : "default_value",
                        DataMap(name: "Altitude", header: "bme280_altitude", svgLogo: altitude) : "default_value",
                        DataMap(name: "Humidité", header: "bme280_humidity", svgLogo: humidity) : "default_value"
                }
        ),

        SensorsData(
                title: "Accéléromètre",
                header: "lsm303_status",

                svgIcon: microchip,
                data: {
                        DataMap(name: "Accélération X", header: "lsm303_accel_x", svgLogo: acceleration) : "default_value",
                        DataMap(name: "Accélération Y", header: "lsm303_accel_y", svgLogo: acceleration) : "default_value",
                        DataMap(name: "Accélération Z", header: "lsm303_accel_z", svgLogo: acceleration) : "default_value",
                        DataMap(name: "Roll", header: "lsm303_roll", svgLogo: pitchAndRoll) : "default_value",
                        DataMap(name: "Pitch", header: "lsm303_pitch", svgLogo: pitchAndRoll) : "default_value",
                        DataMap(name: "Accélération Range", header: "lsm303_accel_range", svgLogo: range) : "default_value"
                }
        ),

        SensorsData(
                title: "GPS",
                header: "gps_status",
                antenna: "gps_antenna_status",
                svgIcon: gps,
                data: {
                        DataMap(name: "Latitude", header: "gps_latitude", svgLogo: gps) : "default_value",
                        DataMap(name: "Longitude", header: "gps_longitude", svgLogo: gps) : "default_value",
                        DataMap(name: "Satelites", header: "gps_satelites", svgLogo: gps) : "default_value",
                        DataMap(name: "HDOP", header: "gps_hdop", svgLogo: gps) : "default_value",
                        DataMap(name: "Antenne", header: "gps_antenna_status", svgLogo: gps) : "default_value"
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
                        DataMap(name: "Vitesse", header: "wind_speed", svgLogo: windSpeed) : "default_value"
                }
        ),

        SensorsData(
                title: "Girouette",
                header: "wind_direction_status",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "Angle", header: "wind_direction_angle", svgLogo: windAngle) : "default_value",
                        DataMap(name: "Orientation", header: "wind_direction_facing", svgLogo: windDirection) : "default_value"
                }
        ),

        SensorsData(
                title: "Luxmètre",
                header: "mb_asl20_status",
                svgIcon: luxmetre,
                data: {
                        DataMap(name: "Luminosité", header: "mb_asl20", svgLogo: luxmetre) : "default_value"
                }
        ),

        SensorsData(
                title: "Thermo-Hygro-Baromètre",
                header: "mb_bme280_status",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "mb_bme280_temp", svgLogo: temperature) : "default_value",
                        DataMap(name: "Pression", header: "mb_bme280_press", svgLogo: pressure) : "default_value",
                        DataMap(name: "Humidité", header: "mb_bme280_hum", svgLogo: humidity) : "default_value"
                }
        )
];

List<SensorsData> stevensonSensors = [
        SensorsData(
                title: "Thermo-Hygro-Baromètre",
                temp: "steve_bme280_temp_status",
                pres: "steve_bme280_pres_status",
                hum: "steve_bme280_hum_status",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "steve_bme280_temp", svgLogo: temperature) : "default_value",
                        DataMap(name: "Pression", header: "steve_bme280_press", svgLogo: pressure) : "default_value",
                        DataMap(name: "Humidité", header: "steve_bme280_hum", svgLogo: humidity) : "default_value"
                }
        ),

        SensorsData(
                title: "Luxmètre",
                header: "steve_veml7700_status",
                svgIcon: luxmetre,
                data: {
                        DataMap(name: "Luminosité", header: "steve_veml7700", svgLogo: luxmetre) : "default_value"
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