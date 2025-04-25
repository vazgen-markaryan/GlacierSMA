/// Analyse une chaîne de données brutes au format texte (3 lignes : entête, en-têtes CSV, valeurs CSV)
/// Met à jour chaque capteur de la liste "sensorGroups" si ses données ont changé.
/// Parcourt chaque groupe de capteurs et met à jour leurs "dataNotifier".
/// si une nouvelle valeur est détectée dans >rawData".

import '../sensors/sensors_data.dart';
import '../utils/switch_utils.dart';

void populateSensorData(String rawData, List<List<SensorsData>> sensorGroups) {
        // Sépare la chaîne reçue en lignes
        final lines = rawData.split('\n');
        if (lines.length < 3) return; // Si format invalide (3 lignes attendues) arrêter

        // Ligne 1 = index 0 (message), Ligne 2 = en-têtes CSV, Ligne 3 = valeurs CSV
        final headers = lines[1].split(',').map((h) => h.trim().toLowerCase()).toList();
        final values = lines[2].split(',').map((v) => v.trim()).toList();

        // Pour chaque capteur de chaque groupe
        for (var sensors in sensorGroups) {
                for (var sensor in sensors) {
                        var hasChanged = false;
                        // Copie en mutable de la map de données
                        final updatedData = Map<DataMap, dynamic>.from(sensor.data);

                        // Pour chaque clé de donnée attendue
                        for (var entry in sensor.data.entries) {
                                final key = entry.key;
                                final index = headers.indexOf(key.header.toLowerCase());

                                if (index == -1) continue; // Si cet en-tête n’existe pas

                                String newValue;

                                // Gestion des cas spéciaux
                                if (key.header == "wind_direction_facing") {
                                        final dir = int.tryParse(values[index]) ?? -1;
                                        newValue = getWindDirectionFacing(dir);
                                }
                                else if (key.header == "gps_antenna_status") {
                                        final ant = int.tryParse(values[index]) ?? -1;
                                        newValue = getGPSAntennaRealValue(ant);
                                }

                                // Valeur numérique générique avec unité
                                else {
                                        final rawVal = double.tryParse(values[index]) ?? 0.0;
                                        newValue = rawVal.toStringAsFixed(2) + getUnitForHeader(key.header);
                                }

                                // Si la donnée a changé, on marque et on met à jour
                                if (updatedData[key] != newValue) {
                                        updatedData[key] = newValue;
                                        hasChanged = true;
                                }
                        }

                        if (hasChanged) {
                                sensor.dataNotifier.value = updatedData;
                        }
                }
        }
}