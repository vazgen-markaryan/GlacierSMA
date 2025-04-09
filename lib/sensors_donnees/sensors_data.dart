import 'package:flutter/material.dart';

class CloudStorageInfo {
        final String? svgSrc, title;
        final int? powerStatus;
        final Color? color;

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
                svgSrc: "assets/icons/microchip.svg",
                powerStatus: 1
        ),
        CloudStorageInfo(
                title: "LSM303",
                svgSrc: "assets/icons/microchip.svg",
                powerStatus: 1
        ),
        CloudStorageInfo(
                title: "VELM7700",
                svgSrc: "assets/icons/microchip.svg",
                powerStatus: 2
        ),
        CloudStorageInfo(
            title: "GPS",
            svgSrc: "assets/icons/microchip.svg",
            powerStatus: 3
        )
];

List<CloudStorageInfo>  windSensors = [
        CloudStorageInfo(
            title: "Wind Speed",
            svgSrc: "assets/icons/ventilation.svg",
            powerStatus: 1
        ),
        CloudStorageInfo(
            title: "Wind Direction",
            svgSrc: "assets/icons/ventilation.svg",
            powerStatus: 0
        )
];

List<CloudStorageInfo>  stevensonSensors = [
        CloudStorageInfo(
            title: "BME280",
            svgSrc: "assets/icons/microchip.svg",
            powerStatus: 1
        ),
        CloudStorageInfo(
            title: "VELM7700",
            svgSrc: "assets/icons/microchip.svg",
            powerStatus: 2
        )
];