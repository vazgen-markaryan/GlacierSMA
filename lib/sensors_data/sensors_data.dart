import 'package:flutter/material.dart';

class CloudStorageInfo {
        String? svgSrc, title, header;
        int? powerStatus;
        Color? color;

        CloudStorageInfo({
                this.svgSrc,
                this.title,
                this.powerStatus,
                this.color,
                this.header
        });
}

List<CloudStorageInfo> internalSensors = [
        CloudStorageInfo(
                title: "BME280",
                header: "bme280_status",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "LSM303",
                header: "lsm303_status",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "VELM7700",
                header: "velm7700_status",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "GPS",
                header: "gps_status",
                svgSrc: "assets/icons/microchip.svg"
        )
];

List<CloudStorageInfo> windSensors = [
        CloudStorageInfo(
                title: "Wind_Speed",
                header: "wind_speed_status",
                svgSrc: "assets/icons/ventilation.svg"
        ),
        CloudStorageInfo(
                title: "Wind_Direction",
                header: "wind_direction_status",
                svgSrc: "assets/icons/ventilation.svg"
        )
];

//TODO headers existent pas. il donne header par valeur et pas par sensor
List<CloudStorageInfo> stevensonSensors = [
        CloudStorageInfo(
                title: "BME280",
                header: "stevenson_bme280_status",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "VELM7700",
                header: "stevenson_velm7700_status",
                svgSrc: "assets/icons/microchip.svg"
        )
];