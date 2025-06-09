import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/test/test_anomaly.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Map des champs à exclure par capteur
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

/// Demande la permission d’accès au stockage adaptée à la version Android.
/// - Pour Android 11+ (API ≥ 30), on demande MANAGE_EXTERNAL_STORAGE.
/// - Pour Android 10 et moins (API ≤ 29), on demande READ/WRITE_EXTERNAL_STORAGE.
/// Retourne `true` si la permission est accordée, `false` sinon.
Future<bool> requestAppropriatePermission(BuildContext context) async {
        if (!Platform.isAndroid) return true;

        // Récupère le niveau d’API Android du périphérique
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) {
                // Sur Android 11+ : MANAGE_EXTERNAL_STORAGE
                if (!await Permission.manageExternalStorage.isGranted) {
                        final status = await Permission.manageExternalStorage.request();
                        return status.isGranted;
                }
                return true;
        }
        else {
                // Sur Android 10 et moins : permissions READ/WRITE_EXTERNAL_STORAGE
                if (!await Permission.storage.isGranted) {
                        final status = await Permission.storage.request();
                        return status.isGranted;
                }
                return true;
        }
}

/// Génère une chaîne CSV à partir d’une liste d’`AnomalyRow`.
/// La première ligne contient les en-têtes localisés, puis chaque anomalie est transformée en une ligne CSV :
/// [Timestamp, Capteur, Propriété, Attendu, Reçu].
String generateCsv(List<AnomalyRow> anomalyLog) {
        // Première ligne : en-têtes localisées
        final rows = <List<dynamic>>[
                [
                        tr('test.csv.timestamp'),
                        tr('test.csv.sensor'),
                        tr('test.csv.property'),
                        tr('test.csv.expected'),
                        tr('test.csv.received')
                ]
        ];

        for (final anomaly in anomalyLog) {
                final ts = anomaly.timestamp;
                final formattedTs =
                        '${ts.hour.toString().padLeft(2, '0')}:'
                        '${ts.minute.toString().padLeft(2, '0')}:'
                        '${ts.second.toString().padLeft(2, '0')} '
                        '${ts.day.toString().padLeft(2, '0')}/'
                        '${ts.month.toString().padLeft(2, '0')}/'
                        '${ts.year}';

                rows.add(
                        [
                                formattedTs,
                                anomaly.sensorName,
                                anomaly.propertyName,
                                anomaly.minMax,
                                anomaly.value
                        ]
                );
        }

        return const ListToCsvConverter().convert(rows);
}

/// Tente de retrouver un dossier public “Download” sur l’appareil Android.
/// Si aucun n’existe, on écrit dans le dossier externe de l’application :
///   /Android/data/<package>/files
Future<Directory> findPublicDownloadDir() async {
        // Liste de chemins “standard” pour le dossier Downloads sur Android
        final candidates = <Directory>[
                Directory('/storage/emulated/0/Download'),
                Directory('/storage/emulated/0/Downloads'),
                Directory('/sdcard/Download'),
                Directory('/sdcard/Downloads')
        ];

        for (final dir in candidates) {
                if (await dir.exists()) {
                        return dir;
                }
        }

        // Si aucun dossier public n’est trouvé, on utilise le répertoire externe de l’app : /Android/data/<package>/files
        final externalAppDir = await getExternalStorageDirectory();
        if (externalAppDir != null) {
                return externalAppDir;
        }

        // En tout dernier recours (normalement ne devrait pas arriver), on retombe sur le répertoire temporaire
        return await getTemporaryDirectory();
}

/// Sauvegarde le contenu CSV dans le répertoire public “Download”.
/// Affiche ensuite un `CustomPopup` indiquant le chemin complet du fichier ou une erreur en cas d’échec.
Future<void> saveCsvToDownloads(
        BuildContext context,
        List<AnomalyRow> anomalyLog
) async {
        try {
                // Génère le texte CSV
                final csvText = generateCsv(anomalyLog);

                // Trouve (ou crée) un dossier “Download” accessible (ou fallback dossier /Android/data/.../files)
                final downloadsDir = await findPublicDownloadDir();

                // Construit un nom de fichier unique basé sur l’horodatage
                final now = DateTime.now();
                final timestamp =
                        '${now.year.toString().padLeft(4, '0')}-'
                        '${now.month.toString().padLeft(2, '0')}-'
                        '${now.day.toString().padLeft(2, '0')}_'
                        '${now.hour.toString().padLeft(2, '0')}-'
                        '${now.minute.toString().padLeft(2, '0')}-'
                        '${now.second.toString().padLeft(2, '0')}';
                final fileName = 'Test_$timestamp.csv';

                // Construit le chemin complet incluant le nom de fichier
                final filePath = '${downloadsDir.path}/';
                final fullFilePath = '${downloadsDir.path}/$fileName';
                final file = File(fullFilePath);

                // Écrit le CSV à l’emplacement choisi
                await file.writeAsString(csvText);

                // Affiche un popup de succès avec le chemin complet
                await showDialog(
                        context: context,
                        builder: (_) => CustomPopup(
                                title: tr('test.succes'),
                                content: Text(
                                        tr('test.file_saved', namedArgs: {'file': fileName}) + '\n$filePath',
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
                // En cas d’erreur, on affiche un popup d’erreur avec le message
                await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CustomPopup(
                                title: tr("test.error"),
                                content: Text(
                                        tr('test.file_error') + '\n$error',
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
                // Ensuite, propager l’erreur pour que le caller décide quoi faire.
                rethrow;
        }
}

/// Affiche une boîte de dialogue demandant à l’utilisateur s’il souhaite exporter les logs.
/// Si l’utilisateur confirme, on appelle `saveCsvToDownloads(...)`.
void showExportConfirmation(
        BuildContext context,
        List<AnomalyRow> anomalyLog
) {
        showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => CustomPopup(
                        title: tr('test.export_logs'),
                        content: Text(
                                tr('test.export_logs_description'),
                                style: const TextStyle(color: Colors.white)
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(tr('test.cancel'))
                                ),
                                TextButton(
                                        onPressed: () {
                                                Navigator.of(context).pop();
                                                saveCsvToDownloads(context, anomalyLog);
                                        },
                                        child: Text(tr('test.save'))
                                )
                        ]
                )
        );
}

/// Affiche le tutoriel / l’introduction au mode Test. Utilisée une seule fois au lancement de l’écran Test, si la permission stockage a été accordée.
void showIntroDialog(BuildContext context) async {
        final prefs = await SharedPreferences.getInstance();
        bool skipTutorial = prefs.getBool('skip_test_tutorial') ?? false;

        showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => StatefulBuilder(
                        builder: (context, setState) {
                                return CustomPopup(
                                        title: tr('test.intro.title'),
                                        content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                        ...List.generate(
                                                                6,
                                                                (i) => Padding(
                                                                        padding: EdgeInsets.only(bottom: 5),
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
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Row(
                                                                children: [
                                                                        Checkbox(
                                                                                value: skipTutorial,
                                                                                onChanged: (val) async {
                                                                                        setState(() => skipTutorial = val ?? false);
                                                                                        await prefs.setBool('skip_test_tutorial', skipTutorial);
                                                                                }
                                                                        ),
                                                                        Expanded(
                                                                                child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                                Text(
                                                                                                        tr("test.skip_tutorial"),
                                                                                                        style: const TextStyle(color: Colors.white)
                                                                                                ),
                                                                                                Padding(
                                                                                                        padding: const EdgeInsets.only(right: 18),
                                                                                                        child: Text(tr("test.skip_tutorial_description"),
                                                                                                                style: const TextStyle(
                                                                                                                        color: Colors.white70,
                                                                                                                        fontSize: 12
                                                                                                                )
                                                                                                        )
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                ]
                                        ),
                                        actions: [
                                                TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('OK')
                                                )
                                        ]
                                );
                        }
                )
        );
}

/// Vérifie si un capteur doit être inclus dans la liste Test.
/// On exclut automatiquement les capteurs IVI (GPS, IRIDIUM, SDCARD) et ceux marqués comme dataProcessor.
/// On exclut également les capteurs inactifs selon le mask.
bool shouldIncludeSensor(SensorsData sensor, int mask) {
        final header = sensor.header?.toLowerCase();
        // Exclut GPS, IRIDIUM, SDCARD ou tout capteur “dataProcessor”
        if (header == 'gps_status' ||
                header == 'iridium_status' ||
                header == 'sdcard' ||
                sensor.dataProcessor != null) return false;

        // Si le bitIndex existe et que le bit correspondant n’est pas dans le mask, on considère que le capteur est inactif
        if (sensor.bitIndex != null && (mask & (1 << sensor.bitIndex!)) == 0)
                return false;

        return true;
}

/// Vérifie si un DataMap (champ d’un capteur) doit être inclus.
/// Consulte [bannedFields] pour éventuellement exclure certains sous-champs.
bool shouldIncludeDataMap(SensorsData sensor, DataMap key) {
        final banned = bannedFields[sensor.header];
        if (banned != null) {
                return !banned.contains(key.header);
        }
        return true; // Par défaut, on inclut tous les autres champs
}

/// Renvoie la plage “min–max” par défaut pour un DataMap donné, à partir de la table `minMaxRanges` définie dans constants.dart.
/// Si aucune plage n’est renseignée, on retourne [0, 999999].
RangeValues getMinMax(SensorsData sensor, DataMap key) {
        return minMaxRanges[sensor.header]?[key.header] ?? const RangeValues(0, 999999);
}