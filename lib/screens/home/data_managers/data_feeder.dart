import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
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
                                        RealValuesHolder().realValues.putIfAbsent(sensor, () => {})[key] = numeric;
                                }
                        }
                }
        }
}

class RealValuesHolder {
        static final RealValuesHolder instance = RealValuesHolder.internal();
        factory RealValuesHolder() => instance;
        RealValuesHolder.internal();

        final Map<SensorsData, Map<DataMap, double>> realValues = {};
}

// Convertit le code de direction du vent (0–16) en texte localisé.
String getWindDirectionFacing(int value) {
        switch (value) {
                case 0:  return tr('global_utilities.wind_direction.north');
                case 1:  return tr('global_utilities.wind_direction.north_northeast');
                case 2:  return tr('global_utilities.wind_direction.northeast');
                case 3:  return tr('global_utilities.wind_direction.east_northeast');
                case 4:  return tr('global_utilities.wind_direction.east');
                case 5:  return tr('global_utilities.wind_direction.east_southeast');
                case 6:  return tr('global_utilities.wind_direction.southeast');
                case 7:  return tr('global_utilities.wind_direction.south_southeast');
                case 8:  return tr('global_utilities.wind_direction.south');
                case 9:  return tr('global_utilities.wind_direction.south_southwest');
                case 10: return tr('global_utilities.wind_direction.southwest');
                case 11: return tr('global_utilities.wind_direction.west_southwest');
                case 12: return tr('global_utilities.wind_direction.west');
                case 13: return tr('global_utilities.wind_direction.west_northwest');
                case 14: return tr('global_utilities.wind_direction.northwest');
                case 15: return tr('global_utilities.wind_direction.north_northwest');
                case 16: return tr('global_utilities.wind_direction.north');
                default: return tr('global_utilities.wind_direction.unknown');
        }
}