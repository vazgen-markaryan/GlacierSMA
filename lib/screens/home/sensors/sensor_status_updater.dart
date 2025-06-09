import 'sensors_data.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

/// Analyse le bloc de <status> pour mettre à jour "powerStatus"
void updateSensorsData(
        String rawData,
        List<SensorsData> Function(SensorType) getSensors,
        String communicationMessageStatus
) {
        // Ne rien faire si pas de balise <status>
        if (!rawData.contains(communicationMessageStatus)) return;

        // Extraire headers et valeurs numériques
        final lines = rawData.split('\n');
        final headers = lines[1].split(',').map((header) => header.trim().toLowerCase()).toList();
        final values = lines[2].split(',').map((value) => int.tryParse(value.trim()) ?? 0).toList();

        // Fonction interne pour mettre à jour chaque liste de capteurs
        void updateSensorStatus(List<SensorsData> sensors) {
                for (var sensor in sensors) {
                        if (sensor.header == null) continue;
                        final index = headers.indexOf(sensor.header!.toLowerCase());
                        sensor.powerStatus = (index != -1) ? values[index] : null;

                        // Forcer la notification même si valeur inchangée
                        sensor.dataNotifier.value = sensor.dataNotifier.value;
                }
        }

        // Mise à jour des groupes de capteurs
        updateSensorStatus(getSensors(SensorType.internal));
        updateSensorStatus(getSensors(SensorType.modbus));
}