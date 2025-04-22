import 'dart:math';
import '../../../constants.dart';
import 'sensors_data.dart';

void updateSensorsData(
        String rawData,
        List<SensorsData> Function(SensorType) getSensors,
        String communicationMessageStatus,
        void Function(int) setTemp,
        void Function(int) setHum,
        void Function(int) setPres
) {
        if (!rawData.contains(communicationMessageStatus)) return;

        final headers = rawData.split('\n')[1].split(',').map((h) => h.trim().toLowerCase()).toList();
        final values = rawData.split('\n')[2].split(',').map((v) => int.tryParse(v.trim()) ?? 0).toList();

        void updateSensorStatus(List<SensorsData> sensors) {
                for (var sensor in sensors) {
                        if (sensor.header == null) continue;

                        if (headers.contains(sensor.header!.toLowerCase())) {
                                sensor.powerStatus = values[headers.indexOf(sensor.header!.toLowerCase())];
                        } else {
                                sensor.powerStatus = null;
                        }

                        // Force un notifyListeners pour que l'UI réagisse au changement
                        sensor.dataNotifier.value = sensor.dataNotifier.value;
                }
        }

        updateSensorStatus(getSensors(SensorType.internal));
        updateSensorStatus(getSensors(SensorType.modbus));
        updateSensorStatus(getSensors(SensorType.stevenson));
        updateSensorStatus(getSensors(SensorType.stevensonStatus));

        final stevenson = getSensors(SensorType.stevenson).first;

        int? localTemp, localHum, localPres;

        final stevensonMapping = {
                stevenson.temp?.toLowerCase():(int status) => localTemp = status,
                stevenson.hum?.toLowerCase():(int status) => localHum = status,
                stevenson.pres?.toLowerCase():(int status) => localPres = status
        };

        for (int i = 0; i < headers.length; i++) {
                stevensonMapping[headers[i]]?.call(values[i]);
        }

        setTemp(localTemp ?? 0);
        setHum(localHum ?? 0);
        setPres(localPres ?? 0);

        stevenson.powerStatus = max(localTemp ?? 0, max(localHum ?? 0, localPres ?? 0));
}