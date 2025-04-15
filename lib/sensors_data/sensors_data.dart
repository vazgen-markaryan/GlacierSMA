import 'package:flutter/material.dart';

// Sensors Icon
const String microchipIcon = "assets/icons/microchip.svg";
const String flashCardIcon = "assets/icons/flash-card.svg";
const String ventilationIcon = "assets/icons/ventilation.svg";
const String luxmetreIcon = "assets/icons/lux.svg";

// Data Icons
const String accelerationIcon = "assets/icons/acceleration.svg";
const String altitudeIcon = "assets/icons/altitude.svg";
const String brightnessIcon = "assets/icons/brightness.svg";
const String gpsIcon = "assets/icons/gps.svg";
const String humidityIcon = "assets/icons/humidity.svg";
const String pitchAndRollIcon = "assets/icons/pitchandroll.svg";
const String pressureIcon = "assets/icons/pressure.svg";
const String temperatureIcon = "assets/icons/temperature.svg";
const String rangeIcon = "assets/icons/range.svg";
const String windDirectionIcon = "assets/icons/wind_direction.svg";
const String windSpeedIcon = "assets/icons/wind_speed.svg";
const String windAngleIcon = "assets/icons/wind_angle.svg";

class Sensors {
        String? svgSrc, title, header, temp, pres, hum, antenna;
        int? powerStatus;
        Color? color;
        Map<DataMap, dynamic> data = {};

        Sensors({
                this.svgSrc,
                this.title,
                this.powerStatus,
                this.color,
                this.header,
                this.temp,
                this.pres,
                this.hum,
                this.antenna,
                required this.data
        });
}

List<Sensors> getSensors(String type) {
        switch (type) {
                case "internal":
                        return internalSensors;
                case "modbus":
                        return modBusSensors;
                case "stevenson":
                        return stevensonSensors;
                case "stevensonStatus":
                        return stevensonStatus;
                default:
                return [];
        }
}

List<Sensors> internalSensors = [
        Sensors(
                title: "Thermo-Hygro-Baromètre",
                header: "bme280_status",
                data: {
                        DataMap(name: "Temperature", header: "bme280_temperature", svgSrc: temperatureIcon) : "default_value",
                        DataMap(name: "Pression", header: "bme280_pression", svgSrc: pressureIcon) : "default_value",
                        DataMap(name: "Altitude", header: "bme280_altitude", svgSrc: altitudeIcon) : "default_value",
                        DataMap(name: "Humidité", header: "bme280_humidity", svgSrc: humidityIcon) : "default_value"
                },
                svgSrc: microchipIcon
        ),
        Sensors(
                title: "Accéléromètre",
                header: "lsm303_status",
                data: {
                        DataMap(name: "Accélération X", header: "lsm303_accel_x", svgSrc: accelerationIcon) : "default_value",
                        DataMap(name: "Accélération Y", header: "lsm303_accel_y", svgSrc: accelerationIcon) : "default_value",
                        DataMap(name: "Accélération Z", header: "lsm303_accel_z", svgSrc: accelerationIcon) : "default_value",
                        DataMap(name: "Roll", header: "lsm303_roll", svgSrc: pitchAndRollIcon) : "default_value",
                        DataMap(name: "Pitch", header: "lsm303_pitch", svgSrc: pitchAndRollIcon) : "default_value",
                        DataMap(name: "Accélération Range", header: "lsm303_accel_range", svgSrc: rangeIcon) : "default_value"
                },
                svgSrc: microchipIcon
        ),
        Sensors(
                title: "GPS",
                header: "gps_status",
                antenna: "gps_antenna_status",
                data: {
                        DataMap(name: "Latitude", header: "gps_latitude", svgSrc: gpsIcon) : "default_value",
                        DataMap(name: "Longitude", header: "gps_longitude", svgSrc: gpsIcon) : "default_value",
                        DataMap(name: "Satelites", header: "gps_satelites", svgSrc: gpsIcon) : "default_value",
                        DataMap(name: "HDOP", header: "gps_hdop", svgSrc: gpsIcon) : "default_value"
                },
                svgSrc: microchipIcon
        ),
        Sensors(
                title: "SD Card",
                header: "sdcard",
                data: {}, // Doit être vide
                svgSrc: flashCardIcon
        )
];

List<Sensors> modBusSensors = [
        Sensors(
                title: "Anémomètre",
                header: "wind_speed_status",
                data: {
                        DataMap(name: "Vitesse", header: "wind_speed", svgSrc: windSpeedIcon) : "default_value"
                },
                svgSrc: ventilationIcon
        ),
        Sensors(
                title: "Girouette",
                header: "wind_direction_status",
                data: {
                        DataMap(name: "Angle", header: "wind_direction_angle", svgSrc: windAngleIcon) : "default_value",
                        DataMap(name: "Orientation", header: "wind_direction_facing", svgSrc: windDirectionIcon) : "default_value"
                },
                svgSrc: ventilationIcon
        ),
        Sensors(
                title: "Luxmètre",
                header: "asl20lux_status",
                data: {
                        DataMap(name: "Luminosité", header: "asl20lux_lux", svgSrc: luxmetreIcon) : "default_value"
                },
                svgSrc: luxmetreIcon
        ),
        Sensors(
                title: "Thermo-Hygro-Baromètre",
                header: "bme280modbus_status",
                data: {
                        DataMap(name: "Temperature", header: "bme280modbus_temperature", svgSrc: temperatureIcon) : "default_value",
                        DataMap(name: "Pression", header: "bme280modbus_pression", svgSrc: pressureIcon) : "default_value",
                        DataMap(name: "Humidité", header: "bme280modbus_humidity", svgSrc: humidityIcon) : "default_value"
                },
                svgSrc: microchipIcon
        )
];

List<Sensors> stevensonSensors = [
        Sensors(
                title: "Thermo-Hygro-Baromètre",
                temp: "stevenson_bme280_temp_status",
                pres: "stevenson_bme280_pres_status",
                hum: "stevenson_bme280_hum_status",
                data: {
                        DataMap(name: "Temperature", header: "bme280_temperature", svgSrc: temperatureIcon) : "default_value",
                        DataMap(name: "Pression", header: "bme280_pression", svgSrc: pressureIcon) : "default_value",
                        DataMap(name: "Humidité", header: "bme280_humidity", svgSrc: humidityIcon) : "default_value"
                },
                svgSrc: microchipIcon),
        Sensors(
                title: "VELM7700",
                header: "stevenson_velm7700_lum_status",
                data: {
                        DataMap(name: "Luminosité", header: "asl20lux_lux", svgSrc: luxmetreIcon) : "default_value"
                },
                svgSrc: microchipIcon)
];

List<Sensors> stevensonStatus = [
        Sensors(
                title: "Stevenson",
                header: "stevenson_status",
                data: {}, // Doit être vide
                svgSrc: microchipIcon)
];

class DataMap {
        String name, header, svgSrc;

        DataMap({
                required this.name,
                required this.header,
                required this.svgSrc
        });
}