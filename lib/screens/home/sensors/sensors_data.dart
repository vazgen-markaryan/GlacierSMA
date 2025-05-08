import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

/// Définit le modèle "DataMap" et "SensorsData", ainsi que la liste par défaut de tous les capteurs et la fonction d’accès.
class DataMap {
        final String name, header, svgLogo;

        const DataMap({
                required this.name,
                required this.header,
                required this.svgLogo
        });
}

class SensorsData {
        String? svgIcon, title, header, temp, pres, hum, code, bus, place;
        Color? color;

        // Bit index (0…15) utilisé par le masque de configuration.
        final int? bitIndex;

        // Notifiers pour valeurs et statut (powerStatus)
        final ValueNotifier<Map<DataMap, dynamic>> dataNotifier;
        final ValueNotifier<int?> powerStatusNotifier;

        int? get powerStatus => powerStatusNotifier.value;
        set powerStatus(int? value) => powerStatusNotifier.value = value;

        SensorsData({
                this.svgIcon, this.title, this.color,
                this.header, this.temp, this.pres,
                this.hum, this.code, this.bitIndex,
                this.bus, this.place,
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
// Ajoute en haut, après ton enum SensorType si tu l'as déjà :

List<SensorsData> getSensors(SensorType type) {
        switch (type) {
                case SensorType.internal:
                        return allSensors
                                .where((s) => s.place == 'Intérieur')
                                .toList();
                case SensorType.modbus:
                        return allSensors
                                .where((s) => s.bus == 'ModBus')
                                .toList();
        }
}


List<SensorsData> allSensors = [
        SensorsData(
                title: "Thermo-Baromètre",
                header: "bme280_status",
                code: "BME280",
                bitIndex: 0,
                bus: "I2C",
                place: "Intérieur",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "bme280_temperature", svgLogo: temperature) : "---",
                        DataMap(name: "Pression", header: "bme280_pression", svgLogo: pressure) : "---",
                        DataMap(name: "Altitude", header: "bme280_altitude", svgLogo: altitude) : "---",
                        DataMap(name: "Humidité", header: "bme280_humidity", svgLogo: humidity) : "---"
                }
        ),

        SensorsData(
                title: "Accéléro-Magnétomètre",
                header: "lsm303_status",
                code: "LSM303",
                bitIndex: 1,
                bus: "I2C",
                place: "Intérieur",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Accélération X", header: "lsm303_accel_x", svgLogo: acceleration) : "---",
                        DataMap(name: "Accélération Y", header: "lsm303_accel_y", svgLogo: acceleration) : "---",
                        DataMap(name: "Accélération Z", header: "lsm303_accel_z", svgLogo: acceleration) : "---",
                        DataMap(name: "Roll", header: "lsm303_roll", svgLogo: pitchAndRoll) : "---",
                        DataMap(name: "Pitch", header: "lsm303_pitch", svgLogo: pitchAndRoll) : "---",
                        DataMap(name: "Accélération Range", header: "lsm303_accel_range", svgLogo: range) : "---"
                }
        ),

        SensorsData(
                title: "GPS",
                header: "gps_status",
                bitIndex: 6,
                bus: "I2C",
                place: "Intérieur",
                svgIcon: gps,
                data: {
                        DataMap(name: "Latitude", header: "gps_latitude", svgLogo: gps) : "---",
                        DataMap(name: "Longitude", header: "gps_longitude", svgLogo: gps) : "---",
                        DataMap(name: "Satelites", header: "gps_satelites", svgLogo: gps) : "---",
                        DataMap(name: "HDOP", header: "gps_hdop", svgLogo: gps) : "---"
                }
        ),

        SensorsData(
                title: "SD Card",
                header: "sdcard",
                bitIndex: 8,
                place: "Intérieur",
                bus: "SPI",
                svgIcon: flashCard,
                data: {} // Doit être vide
        ),

        SensorsData(
                title: "Iriduim",
                header: "iridium_status",
                bitIndex: 9,
                code: "RockBLOCK",
                place: "Intérieur",
                svgIcon: satellite,
                data: {
                        DataMap(name: "Qualité du signal", header: "iridium_signal_quality", svgLogo: satellite) : "---",
                }
        ),

        SensorsData(
                title: "Anémomètre",
                header: "wind_speed_status",
                bitIndex: 2,
                bus: "ModBus",
                place: "Extérieur",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "Vitesse", header: "wind_speed", svgLogo: windSpeed) : "---"
                }
        ),

        SensorsData(
                title: "Girouette",
                header: "wind_direction_status",
                bitIndex: 3,
                bus: "ModBus",
                place: "Extérieur",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "Angle", header: "wind_direction_angle", svgLogo: windAngle) : "---",
                        DataMap(name: "Orientation", header: "wind_direction_facing", svgLogo: windDirection) : "---"
                }
        ),

        SensorsData(
                title: "Luxmètre",
                header: "mb_asl20_status",
                code: "ASL20",
                bitIndex: 4,
                bus: "ModBus",
                place: "Extérieur",
                svgIcon: luxmetre,
                data: {
                        DataMap(name: "Luminosité", header: "mb_asl20", svgLogo: luxmetre) : "---"
                }
        ),

        SensorsData(
                title: "Thermo-Baromètre",
                header: "mb_bme280_status",
                code: "BME280",
                bitIndex: 5,
                bus: "ModBus",
                place: "Extérieur",
                svgIcon: microchip,
                data: {
                        DataMap(name: "Temperature", header: "mb_bme280_temp", svgLogo: temperature) : "---",
                        DataMap(name: "Pression", header: "mb_bme280_press", svgLogo: pressure) : "---",
                        DataMap(name: "Humidité", header: "mb_bme280_hum", svgLogo: humidity) : "---"
                }
        )
];