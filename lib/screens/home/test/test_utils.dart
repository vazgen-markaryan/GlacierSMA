import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_anomaly_row.dart';

// Map des champs à exclure par capteur
final Map<String, Set<String>> bannedFields = {
        "lsm303_status": {
                "lsm303_accel_x",
                "lsm303_accel_y",
                "lsm303_accel_z",
                "lsm303_accel_range"
        },
        "wind_direction_status": {
                "wind_direction_facing"
        }
};

Future<bool> requestAppropriatePermission(BuildContext context) async {
        if (!Platform.isAndroid) return true;

        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) {
                if (!await Permission.manageExternalStorage.isGranted) {
                        final status = await Permission.manageExternalStorage.request();
                        return status.isGranted;
                }
                return true;
        }
        else {
                if (!await Permission.storage.isGranted) {
                        final status = await Permission.storage.request();
                        return status.isGranted;
                }
                return true;
        }
}

String generateCsv(List<AnomalyRow> anomalyLog) {
        final rows = <List<dynamic>>[['Timestamp', 'Capteur', 'Propriété', 'Attendu', 'Reçu']];
        for (final anomaly in anomalyLog) {
                final ts = anomaly.timestamp;
                final formattedTs =
                        '${ts.hour.toString().padLeft(2, '0')}:'
                        '${ts.minute.toString().padLeft(2, '0')}:'
                        '${ts.second.toString().padLeft(2, '0')} '
                        '${ts.day.toString().padLeft(2, '0')}/'
                        '${ts.month.toString().padLeft(2, '0')}/'
                        '${ts.year}';
                rows.add([
                                formattedTs,
                                anomaly.sensorName,
                                anomaly.propertyName,
                                anomaly.minMax,
                                anomaly.value
                        ]);
        }
        return const ListToCsvConverter().convert(rows);
}

Future<Directory> findPublicDownloadDir() async {
        final candidates = <Directory>[
                Directory('/storage/emulated/0/Download'),
                Directory('/storage/emulated/0/Downloads'),
                Directory('/sdcard/Download'),
                Directory('/sdcard/Downloads')
        ];

        for (final directory in candidates) {
                if (await directory.exists()) {
                        return directory;
                }
        }
        return await getTemporaryDirectory();
}

Future<void> saveCsvToDownloads(BuildContext context, List<AnomalyRow> anomalyLog) async {
        try {
                final csvText = generateCsv(anomalyLog);
                final downloadsDir = await findPublicDownloadDir();
                final now = DateTime.now();
                final timestamp =
                        '${now.year.toString().padLeft(4, '0')}-'
                        '${now.month.toString().padLeft(2, '0')}-'
                        '${now.day.toString().padLeft(2, '0')}_'
                        '${now.hour.toString().padLeft(2, '0')}-'
                        '${now.minute.toString().padLeft(2, '0')}-'
                        '${now.second.toString().padLeft(2, '0')}';
                final fileName = 'Test_$timestamp.csv';
                final fullPath = '${downloadsDir.path}/$fileName';
                final file = File(fullPath);
                await file.writeAsString(csvText);

                showDialog(
                        context: context,
                        builder: (_) => CustomPopup(
                                title: 'Succès',
                                content: Text(
                                        'Fichier enregistré :\n$fullPath',
                                        style: const TextStyle(color: Colors.white)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('OK')
                                        )
                                ]
                        )
                );
        }
        catch (error) {
                showDialog(
                        context: context,
                        builder: (_) => CustomPopup(
                                title: 'Erreur',
                                content: Text(
                                        'Une erreur est survenue lors de l’enregistrement du fichier :\n$error',
                                        style: const TextStyle(color: Colors.white)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('OK')
                                        )
                                ]
                        )
                );
        }
}

void showExportConfirmation(BuildContext context, List<AnomalyRow> anomalyLog) {
        showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => CustomPopup(
                        title: 'Exporter les logs',
                        content: const Text(
                                'Voulez-vous enregistrer les logs du test ?\n'
                                'Le fichier sera créé dans “Téléchargements”.',
                                style: TextStyle(color: Colors.white)
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Annuler')
                                ),
                                TextButton(
                                        onPressed: () {
                                                Navigator.of(context).pop();
                                                saveCsvToDownloads(context, anomalyLog);
                                        },
                                        child: const Text('Enregistrer')
                                )
                        ]
                )
        );
}

void showIntroDialog(BuildContext context) {
        showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                CustomPopup(
                        title: tr('test.intro.title'),
                        content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(7, (i) =>
                                        Padding(
                                                padding: EdgeInsets.only(bottom: i < 6 ? 8 : 0),
                                                child: Text(
                                                        tr('test.intro.description_${i + 1}'),
                                                        style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 16,
                                                                height: 1.5,
                                                                fontWeight: FontWeight.w400
                                                        )
                                                )
                                        )
                                )
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK')
                                )
                        ]
                )
        );
}

bool shouldIncludeSensor(SensorsData sensor, int mask) {
        final header = sensor.header?.toLowerCase();
        // Exclut certains capteurs et ceux avec un dataProcessor
        if (header == 'gps_status' || header == 'iridium_status' || header == 'sdcard' || sensor.dataProcessor != null) return false;
        // Exclut les capteurs inactifs selon le mask
        if (sensor.bitIndex != null && (mask & (1 << sensor.bitIndex!)) == 0) return false;
        return true;
}

// Methode utilitaire pour vérifier si un DataMap doit être inclus
bool shouldIncludeDataMap(SensorsData sensor, DataMap key) {
        final banned = bannedFields[sensor.header];

        if (banned != null) {
                return !banned.contains(key.header);
        }
        return true; // Par défaut, inclure tout
}

RangeValues getMinMax(SensorsData sensor, DataMap key) {
        return minMaxRanges[sensor.header]?[key.header] ?? const RangeValues(0, 999999);
}