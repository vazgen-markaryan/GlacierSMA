import '../utils/dashboard_utils.dart';
import '../sensors/sensors_data.dart';

void populateSensorData(String rawData, List<List<SensorsData>> sensorGroups) {
        final lines = rawData.split('\n');
        if (lines.length < 3) return;

        final headers = lines[1].split(',').map((h) => h.trim().toLowerCase()).toList();
        final values = lines[2].split(',').map((v) => v.trim()).toList();

        for (var sensors in sensorGroups) {
                for (var sensor in sensors) {
                        bool hasChanged = false;
                        final updatedData = Map<DataMap, dynamic>.from(sensor.data);

                        for (var entry in sensor.data.entries) {
                                final key = entry.key;
                                final headerIndex = headers.indexOf(key.header.toLowerCase());

                                if (headerIndex != -1) {
                                        String newValue;

                                        if (key.header == "wind_direction_facing") {
                                                final directionValue = int.tryParse(values[headerIndex]) ?? -1;
                                                newValue = getWindDirectionFacing(directionValue);
                                        }
                                        else if (key.header == "gps_antenna_status") {
                                                final antennaValue = int.tryParse(values[headerIndex]) ?? -1;
                                                newValue = getGPSAntennaRealValue(antennaValue);
                                        }
                                        else {
                                                final rawValue = double.tryParse(values[headerIndex]) ?? 0.0;
                                                newValue = rawValue.toStringAsFixed(2) + getUnitForHeader(key.header);
                                        }

                                        if (updatedData[key] != newValue) {
                                                updatedData[key] = newValue;
                                                hasChanged = true;
                                        }
                                }
                        }

                        if (hasChanged) {
                                sensor.dataNotifier.value = updatedData;
                        }
                }
        }
}