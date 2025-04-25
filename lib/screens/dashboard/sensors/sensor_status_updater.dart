/// Analyse le bloc de <status> pour mettre à jour "powerStatus"

import 'dart:math';
import 'sensors_data.dart';
import '../utils/constants.dart';

void updateSensorsData(
        String rawData,
        List<SensorsData> Function(SensorType) getSensors,
        String communicationMessageStatus,
        void Function(int) setTemp,
        void Function(int) setHum,
        void Function(int) setPres
) {
        // Ne rien faire si pas de balise <status>
        if (!rawData.contains(communicationMessageStatus)) return;

        // Extraire headers et valeurs numériques
        final lines = rawData.split('\n');
        final headers = lines[1].split(',').map((h) => h.trim().toLowerCase()).toList();
        final values = lines[2].split(',').map((v) => int.tryParse(v.trim()) ?? 0).toList();

        // Fonction interne pour mettre à jour chaque liste de capteurs
        void updateSensorStatus(List<SensorsData> sensors) {
                for (var sensor in sensors) {
                        if (sensor.header == null) continue;
                        final idx = headers.indexOf(sensor.header!.toLowerCase());
                        sensor.powerStatus = (idx != -1) ? values[idx] : null;
                        // Forcer la notif même si valeur inchangée
                        sensor.dataNotifier.value = sensor.dataNotifier.value;
                }
        }

        // Mise à jour des 4 groupes
        updateSensorStatus(getSensors(SensorType.internal));
        updateSensorStatus(getSensors(SensorType.modbus));
        updateSensorStatus(getSensors(SensorType.stevenson));
        updateSensorStatus(getSensors(SensorType.stevensonStatus));

        // Extraire statuts pour Stevenson local (temp/hum/pres)
        final stevenson = getSensors(SensorType.stevenson).first;
        int? localTemp, localHum, localPres;
        final mapping = {
                stevenson.temp?.toLowerCase():(int s) => localTemp = s,
                stevenson.hum?.toLowerCase():(int s) => localHum = s,
                stevenson.pres?.toLowerCase():(int s) => localPres = s
        };

        for (var i = 0; i < headers.length; i++) {
                mapping[headers[i]]?.call(values[i]);
        }

        // Notifier les callbacks externes
        setTemp(localTemp ?? 0);
        setHum(localHum ?? 0);
        setPres(localPres ?? 0);

        // Met à jour le powerStatus global de Stevenson
        stevenson.powerStatus =
        max(localTemp ?? 0, max(localHum ?? 0, localPres ?? 0));
}