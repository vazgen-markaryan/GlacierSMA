import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
        String? svgIcon, title, header, temp, pres, hum, codeName, bus, placement, dataProcessor;
        Color? color;

        // Bit index (0…15) utilisé par le masque de configuration.
        final int? bitIndex, maskValue;

        // Notifiers pour valeurs et statut (powerStatus)
        final ValueNotifier<Map<DataMap, dynamic>> dataNotifier;
        final ValueNotifier<int?> powerStatusNotifier;

        int? get powerStatus => powerStatusNotifier.value;
        set powerStatus(int? value) => powerStatusNotifier.value = value;

        SensorsData({
                this.svgIcon, this.title, this.color,
                this.header, this.temp, this.pres,
                this.hum, this.codeName, this.bitIndex,
                this.bus, this.placement, this.dataProcessor,
                required Map<DataMap, dynamic> data,
                int? powerStatus
        }) : dataNotifier = ValueNotifier(data),
                powerStatusNotifier = ValueNotifier(powerStatus),
                maskValue = bitIndex != null ? (1 << bitIndex) : null;

        Map<DataMap, dynamic> get data => dataNotifier.value;

        // Historique pour chaque DataMap (liste de FlSpot(x=sec,y=val))
        final Map<DataMap, List<FlSpot>> history = {};
        final DateTime start = DateTime.now();

        /// Met à jour uniquement le libellé affiché (popup texte)
        void updateFormatted(DataMap key, String formatted) {
                // On clone la map courante et on change la valeur pour ce key
                final updated = Map<DataMap, dynamic>.from(dataNotifier.value);
                updated[key] = formatted;
                dataNotifier.value = updated;
        }

        /// Enregistre à chaque trame la composante numérique pour tracer le graph
        void recordHistory(DataMap key, double newValue) {
                final elapsed = DateTime.now().difference(start).inSeconds.toDouble();
                final list = history.putIfAbsent(key, () => []);
                list.add(FlSpot(elapsed, newValue));

                // Ne garder que les 60 dernières secondes
                while (list.isNotEmpty && elapsed - list.first.x > 60) {
                        list.removeAt(0);
                }
        }
}

// Fonction d’accès à la liste de capteurs selon le type
// Ajoute en haut, après ton enum SensorType si tu l'as déjà :

List<SensorsData> getSensors(SensorType type) {
        switch (type) {
                case SensorType.internal:
                        return allSensors
                                .where((s) => s.bus == 'I2C' || s.bus == 'SPI' || s.dataProcessor == 'true')
                                .toList();
                case SensorType.modbus:
                        return allSensors
                                .where((s) => s.bus == 'ModBus')
                                .toList();
        }
}

List<SensorsData> allSensors = [
        SensorsData(
                title: "sensor-data.title.thermo_barometer",
                header: "bme280_status",
                codeName: "BME280",
                bitIndex: 0,
                bus: "I2C",
                placement: "sensor-data.placement.interior",
                svgIcon: microchip,
                data: {
                        DataMap(name: "sensor-data.datamap.temperature", header: "bme280_temperature", svgLogo: temperature) : "---",
                        DataMap(name: "sensor-data.datamap.pressure", header: "bme280_pression", svgLogo: pressure) : "---",
                        DataMap(name: "sensor-data.datamap.altitude", header: "bme280_altitude", svgLogo: altitude) : "---",
                        DataMap(name: "sensor-data.datamap.humidity", header: "bme280_humidity", svgLogo: humidity) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.accel_magnetometer",
                header: "lsm303_status",
                codeName: "LSM303",
                bitIndex: 1,
                bus: "I2C",
                placement: "sensor-data.placement.interior",
                svgIcon: microchip,
                data: {
                        DataMap(name: "sensor-data.datamap.accel_x", header: "lsm303_accel_x", svgLogo: acceleration) : "---",
                        DataMap(name: "sensor-data.datamap.accel_y", header: "lsm303_accel_y", svgLogo: acceleration) : "---",
                        DataMap(name: "sensor-data.datamap.accel_z", header: "lsm303_accel_z", svgLogo: acceleration) : "---",
                        DataMap(name: "sensor-data.datamap.roll", header: "lsm303_roll", svgLogo: pitchAndRoll) : "---",
                        DataMap(name: "sensor-data.datamap.pitch", header: "lsm303_pitch", svgLogo: pitchAndRoll) : "---",
                        DataMap(name: "sensor-data.datamap.accel_range", header: "lsm303_accel_range", svgLogo: range) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.gps",
                header: "gps_status",
                bitIndex: 6,
                bus: "I2C",
                placement: "sensor-data.placement.interior",
                svgIcon: gps,
                data: {
                        DataMap(name: "sensor-data.datamap.latitude", header: "gps_latitude", svgLogo: gps) : "---",
                        DataMap(name: "sensor-data.datamap.longitude", header: "gps_longitude", svgLogo: gps) : "---",
                        DataMap(name: "sensor-data.datamap.satellites", header: "gps_satelites", svgLogo: gps) : "---",
                        DataMap(name: "sensor-data.datamap.hdop", header: "gps_hdop", svgLogo: gps) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.sd_card",
                header: "sdcard",
                bitIndex: 8,
                placement: "sensor-data.placement.interior",
                bus: "SPI",
                dataProcessor: "true",
                svgIcon: flashCard,
                data: {} // Doit être vide
        ),

        SensorsData(
                title: "sensor-data.title.iridium",
                header: "iridium_status",
                bitIndex: 9,
                codeName: "RockBLOCK",
                placement: "sensor-data.placement.interior",
                dataProcessor: "true",
                svgIcon: satellite,
                data: {
                        DataMap(name: "sensor-data.datamap.iridium_quality", header: "iridium_signal_quality", svgLogo: satellite) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.anemometer",
                header: "wind_speed_status",
                bitIndex: 2,
                bus: "ModBus",
                placement: "sensor-data.placement.exterior",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "sensor-data.datamap.wind_speed", header: "wind_speed", svgLogo: windSpeed) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.wind_vane",
                header: "wind_direction_status",
                bitIndex: 3,
                bus: "ModBus",
                placement: "sensor-data.placement.exterior",
                svgIcon: ventilation,
                data: {
                        DataMap(name: "sensor-data.datamap.wind_direction_angle", header: "wind_direction_angle", svgLogo: windAngle) : "---",
                        DataMap(name: "sensor-data.datamap.wind_direction_facing", header: "wind_direction_facing", svgLogo: windDirection) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.lux_meter",
                header: "mb_asl20_status",
                codeName: "ASL20",
                bitIndex: 4,
                bus: "ModBus",
                placement: "sensor-data.placement.exterior",
                svgIcon: luxmetre,
                data: {
                        DataMap(name: "sensor-data.datamap.lux", header: "mb_asl20", svgLogo: luxmetre) : "---"
                }
        ),

        SensorsData(
                title: "sensor-data.title.thermo_barometer",
                header: "mb_bme280_status",
                codeName: "BME280",
                bitIndex: 5,
                bus: "ModBus",
                placement: "sensor-data.placement.exterior",
                svgIcon: microchip,
                data: {
                        DataMap(name: "sensor-data.datamap.mb_temperature", header: "mb_bme280_temp", svgLogo: temperature) : "---",
                        DataMap(name: "sensor-data.datamap.mb_pressure", header: "mb_bme280_press", svgLogo: pressure) : "---",
                        DataMap(name: "sensor-data.datamap.mb_humidity", header: "mb_bme280_hum", svgLogo: humidity) : "---"
                }
        )
];