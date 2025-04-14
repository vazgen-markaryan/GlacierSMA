import 'package:flutter/material.dart';

const String microchipIcon = "assets/icons/microchip.svg";
const String flashCardIcon = "assets/icons/flash-card.svg";
const String ventilationIcon = "assets/icons/ventilation.svg";
const String luxmetreIcon = "assets/icons/lux.svg";

class CloudStorageInfo {
        String? svgSrc, title, header, temp, pres, hum, antenna;
        int? powerStatus;
        Color? color;

        CloudStorageInfo({
                this.svgSrc,
                this.title,
                this.powerStatus,
                this.color,
                this.header,
                this.temp,
                this.pres,
                this.hum,
                this.antenna
        });
}

List<CloudStorageInfo> getSensors(String type) {
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

List<CloudStorageInfo> internalSensors = [
        CloudStorageInfo(title: "BME280", header: "bme280_status", svgSrc: microchipIcon),
        CloudStorageInfo(title: "LSM303", header: "lsm303_status", svgSrc: microchipIcon),
        CloudStorageInfo(title: "GPS", header: "gps_status", antenna: "gps_antenna_status", svgSrc: microchipIcon),
        CloudStorageInfo(title: "SD Card", header: "sdcard", svgSrc: flashCardIcon)
];

List<CloudStorageInfo> modBusSensors = [
        CloudStorageInfo(title: "Wind_Speed", header: "wind_speed_status", svgSrc: ventilationIcon),
        CloudStorageInfo(title: "Wind_Direction", header: "wind_direction_status", svgSrc: ventilationIcon),
        CloudStorageInfo(title: "Luxmètre", header: "asl20lux_status", svgSrc: luxmetreIcon)
];

List<CloudStorageInfo> stevensonSensors = [
        CloudStorageInfo(title: "BME280", temp: "stevenson_bme280_temp_status", pres: "stevenson_bme280_pres_status", hum: "stevenson_bme280_hum_status", svgSrc: microchipIcon),
        CloudStorageInfo(title: "VELM7700", header: "stevenson_velm7700_lum_status", svgSrc: microchipIcon)
];

List<CloudStorageInfo> stevensonStatus = [
        CloudStorageInfo(title: "Stevenson", header: "stevenson_status", svgSrc: microchipIcon)
];