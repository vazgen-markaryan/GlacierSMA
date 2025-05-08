import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Analyse une chaîne de données brutes au format texte (>=3 lignes : message, en-têtes CSV, valeurs CSV)
/// Met à jour les `dataNotifier` de chaque capteur si la valeur associée a changé.

void populateSensorData(
        String rawData,
        List<List<SensorsData>> sensorGroups
) {
        // Découpage en lignes
        final lines = rawData.split('\n');

        if (lines.length < 3) return; // Format invalide

        // 2) Extraction des en-têtes et valeurs
        final headers = lines[1]
                .split(',')
                .map((h) => h.trim().toLowerCase())
                .toList();
        final values = lines[2]
                .split(',')
                .map((v) => v.trim())
                .toList();

        // Pour chaque groupe de capteurs
        for (final sensors in sensorGroups) {
                for (final sensor in sensors) {
                        var hasChanged = false;
                        // Copie mutable des données actuelles
                        final updatedData = Map<DataMap, dynamic>.from(sensor.data);

                        // Parcours de chaque DataMap attendue
                        for (final entry in sensor.data.entries) {
                                final key = entry.key;
                                final index = headers.indexOf(key.header.toLowerCase());

                                if (index == -1) continue; // Colonne non trouvée

                                String newValue;

                                // Cas spécial : orientation du vent
                                if (key.header == 'wind_direction_facing') {
                                        final dir = int.tryParse(values[index]) ?? -1;
                                        newValue = getWindDirectionFacing(dir);
                                }
                                // Cas Iridium : on conserve la valeur brute (0–5)
                                else if (key.header.toLowerCase() == 'iridium_signal_quality') {
                                        newValue = values[index];
                                }
                                // Valeur numérique générique + unité
                                else {
                                        final raw = values[index];
                                        final num = double.tryParse(raw);
                                        if (num != null) {
                                                newValue = '${num.toStringAsFixed(2)}${getUnitForHeader(key.header)}';
                                        }
                                        else {
                                                newValue = raw;
                                        }
                                }

                                // Mise à jour si différent
                                if (updatedData[key] != newValue) {
                                        updatedData[key] = newValue;
                                        hasChanged = true;
                                }
                        }

                        // Notification du changement
                        if (hasChanged) {
                                sensor.dataNotifier.value = updatedData;
                        }
                }
        }
}