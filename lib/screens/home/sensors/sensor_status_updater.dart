import 'sensors_data.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

/// Mise à jour des états powerStatus à partir du bloc <status>
void updateSensorsData(
        String rawData,
        List<SensorsData> Function(SensorType) getSensors,
        String communicationMessageStatus
) {
        // Protection : uniquement si <status> présent
        if (!rawData.contains(communicationMessageStatus)) return;

        final lines = rawData.split('\n');

        // Nettoyage de la dernière ligne (padding possible venant d'Arduino BLE)
        final cleanedLine = lines[2].replaceAll(RegExp(r'\x00'), '');

        final headers = lines[1]
                .split(',')
                .map((header) => header.trim().toLowerCase())
                .toList();

        final values = cleanedLine
                .split(',')
                .map((value) => int.tryParse(value.trim()) ?? 0)
                .toList();

        // Applique les statuts individuellement aux sensors existants
        void updateSensorStatus(List<SensorsData> sensors) {
                for (var sensor in sensors) {
                        if (sensor.header == null) continue;

                        final index = headers.indexOf(sensor.header!.toLowerCase());
                        if (index == -1) {
                                sensor.powerStatus = 0;
                                sensor.dataNotifier.value = sensor.dataNotifier.value;
                                continue;
                        }

                        final rawValue = values[index];
                        sensor.powerStatus = rawValue;
                        sensor.dataNotifier.value = sensor.dataNotifier.value;
                }
        }

        // Applique sur les deux familles de capteurs
        updateSensorStatus(getSensors(SensorType.internal));
        updateSensorStatus(getSensors(SensorType.modbus));
}