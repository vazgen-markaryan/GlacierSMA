import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Analyse une chaîne de données brutes au format texte (>=3 lignes : message, en-têtes CSV, valeurs CSV)
/// Met à jour les `dataNotifier` de chaque capteur si la valeur associée a changé.
void populateSensorData(
        String rawData,
        List<List<SensorsData>> sensorGroups
) {
        final lines = rawData.split('\n');
        if (lines.length < 3) return;

        final headers = lines[1].split(',').map((h) => h.trim().toLowerCase()).toList();
        final values = lines[2].split(',').map((v) => v.trim()).toList();

        for (final sensors in sensorGroups) {
                for (final sensor in sensors) {
                        for (final entry in sensor.data.entries) {
                                final key = entry.key;
                                final idx = headers.indexOf(key.header.toLowerCase());
                                if (idx < 0) continue;

                                String formatted;
                                double? numeric;

                                // Calcul du texte ET de la valeur numérique
                                if (key.header == 'wind_direction_facing') {
                                        formatted = getWindDirectionFacing(int.tryParse(values[idx]) ?? -1);
                                        numeric = null;
                                }
                                else if (key.header.toLowerCase() == 'iridium_signal_quality') {
                                        formatted = values[idx];
                                        numeric = double.tryParse(values[idx]);
                                }
                                else {
                                        final raw = values[idx];
                                        final n = double.tryParse(raw);
                                        if (n != null) {
                                                // texte limité à 2 décimales
                                                formatted = '${n.toStringAsFixed(2)}${getUnitForHeader(key.header)}';
                                                numeric = double.parse(n.toStringAsFixed(2));
                                        }
                                        else {
                                                formatted = raw;
                                                numeric = null;
                                        }
                                }

                                // Mise à jour du popup texte si nécessaire
                                if (sensor.data[key] != formatted) {
                                        sensor.updateFormatted(key, formatted);
                                }

                                // Enregistrement à chaque fois pour le graphique
                                if (numeric != null) {
                                        sensor.recordHistory(key, numeric);
                                }
                        }
                }
        }
}