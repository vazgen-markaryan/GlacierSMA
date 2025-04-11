import 'package:flutter/material.dart';

class CloudStorageInfo {
        String? svgSrc, title;
        int? powerStatus;
        Color? color;

        CloudStorageInfo({
                this.svgSrc,
                this.title,
                this.powerStatus,
                this.color
        });
}

List<CloudStorageInfo> internalSensors = [
        CloudStorageInfo(
                title: "BME280",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "LSM303",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "VELM7700",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "GPS",
                svgSrc: "assets/icons/microchip.svg"
        )
];

List<CloudStorageInfo> windSensors = [
        CloudStorageInfo(
                title: "Wind_Speed",
                svgSrc: "assets/icons/ventilation.svg"
        ),
        CloudStorageInfo(
                title: "Wind_Direction",
                svgSrc: "assets/icons/ventilation.svg"
        )
];

List<CloudStorageInfo> stevensonSensors = [
        CloudStorageInfo(
                title: "BME280",
                svgSrc: "assets/icons/microchip.svg"
        ),
        CloudStorageInfo(
                title: "VELM7700",
                svgSrc: "assets/icons/microchip.svg"
        )
];