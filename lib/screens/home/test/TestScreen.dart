import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_feeder.dart';


/// Écran de test en environnement contrôlé
class TestScreen extends StatefulWidget {
        final ValueListenable<int?> activeMaskNotifier;
        final List<SensorsData> Function(SensorType) getSensors;
        final ValueNotifier<int> iterationNotifier;

        const TestScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.getSensors,
                required this.iterationNotifier
        }) : super(key: key);

        @override
        State<TestScreen> createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
        // Map pour stocker les plages de valeurs par DataMap
        final Map<SensorsData, Map<DataMap, RangeValues>> ranges = {};

        // Map pour les valeurs par défaut
        final Map<SensorsData, Map<DataMap, RangeValues>> defaultRanges = {};

        // Map pour stocker les min/max par capteur et son DataMap
        final Map<SensorsData, Map<DataMap, RangeValues>> dataMapMinMax = {};

        // Liste des logs pour le test
        final List<String> logs = [];

        // Indicateur pour savoir si le test est en cours
        bool isTesting = false;

        // La dernière itération du test
        int lastIteration = 0;

        // Liste des anomalies détectées
        final List<AnomalyRow> anomalyLog = [];

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

        bool shouldIncludeDataMap(SensorsData sensor, DataMap key) {
                final banned = bannedFields[sensor.header];

                if (banned != null) {
                        return !banned.contains(key.header);
                }
                return true; // Par défaut, inclure tout
        }

        @override
        void initState() {
                super.initState();
                final mask = widget.activeMaskNotifier.value ?? 0;
                widget.iterationNotifier.addListener(onNewIteration);

                for (var sensor in widget.getSensors(SensorType.internal) +
                        widget.getSensors(SensorType.modbus)) {
                        if (!isActive(sensor, mask)) continue;
                        final dataMap = <DataMap, RangeValues>{};
                        for (var key in sensor.data.keys) {
                                if (!shouldIncludeDataMap(sensor, key)) continue;
                                dataMap[key] = getMinMax(sensor, key);
                        }
                        dataMapMinMax[sensor] = dataMap;
                        defaultRanges[sensor] = Map.of(dataMap);
                        ranges[sensor] = Map.of(dataMap);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => showIntroDialog());
        }

        @override
        void dispose() {
                widget.iterationNotifier.removeListener(onNewIteration);
                super.dispose();
        }

        RangeValues getMinMax(SensorsData sensor, DataMap key) {
                return minMaxRanges[sensor.header]?[key.header] ??
                        const RangeValues(0, 999999);
        }

        bool isActive(SensorsData sensor, int mask) {
                final header = sensor.header?.toLowerCase();
                if (header == 'gps_status' || header == 'iridium_status' ||
                        header == 'sdcard' || sensor.dataProcessor != null) return false;
                if (sensor.bitIndex != null && (mask & (1 << sensor.bitIndex!)) == 0)
                        return false;
                return true;
        }

        void showIntroDialog() {
                showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                        CustomPopup(
                                title: tr('test.intro.title'),
                                content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: List.generate(
                                                7,
                                                (i) =>
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

        void showRangeDialog(SensorsData sensor) {
                showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: '',
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (_, __, ___) =>
                        RangePopup(
                                sensor: sensor,
                                defaults: defaultRanges[sensor]!,
                                currents: ranges[sensor]!,
                                onApply: (updated) =>
                                setState(() => ranges[sensor] = Map.of(updated))
                        ),
                        transitionBuilder: (context, animation, _, child) =>
                        Transform.scale(
                                scale: Curves.easeOutBack.transform(animation.value),
                                child: child
                        )
                );
        }

        bool get hasChanges {
                for (var sensor in ranges.keys) {
                        final current = ranges[sensor]!;
                        final defaults = defaultRanges[sensor]!;
                        if (current.length != defaults.length) return true;
                        for (var k in current.keys) {
                                if (current[k] != defaults[k]) return true;
                        }
                }
                return false;
        }

        void launchTest() {
                setState(() {
                                isTesting = true;
                                logs.clear();
                                anomalyLog.clear();
                                lastIteration = 0;
                        }
                );
        }

        void stopTest() async {
                setState(() {
                                isTesting = false;
                        }
                );
                final save = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CustomPopup(
                                title: 'Test terminé',
                                content: const Text('Exporter les logs du test ?'),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Non')
                                        ),
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Oui')
                                        )
                                ]
                        )
                );
                if (save == true) {
                        await _exportLogs();
                }
        }

        @override
        Widget build(BuildContext context) {
                return WillPopScope(
                        // On empêche le pop tant que isTesting == true
                        onWillPop: () async {
                                if (isTesting) {
                                        // Optionnel : tu peux afficher un petit snack ou popup pour le dire
                                        ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Arrêtez d’abord le test"))
                                        );
                                        return false;
                                }
                                return true;
                        },
                        child: Scaffold(
                                body: isTesting ? buildLogScreen() : buildConfigScreen()
                        )
                );
        }

        Widget buildConfigScreen() {
                return SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                                children: [
                                        ...createAllSensorGroups(
                                                maskNotifier: widget.activeMaskNotifier,
                                                getSensors: widget.getSensors,
                                                onTap: (ctx, s) => showRangeDialog(s),
                                                configMode: false,
                                                testMode: true
                                        ),

                                        const SizedBox(height: defaultPadding),

                                        SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                        onPressed: () => onLaunchTestPressed(context),
                                                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                        label: const Text(
                                                                'Lancer Test', style: TextStyle(color: Colors.white)),
                                                        style: ElevatedButton.styleFrom(
                                                                backgroundColor: Theme
                                                                        .of(context)
                                                                        .primaryColor
                                                        )
                                                )
                                        )
                                ]
                        )
                );
        }

        void onLaunchTestPressed(BuildContext context) {
                if (!hasChanges) {
                        showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) =>
                                CustomPopup(
                                        title: 'Confirmation',
                                        content: const Text(
                                                'Vous runnez le test avec les valeurs par défaut ?',
                                                style: TextStyle(color: Colors.white, fontSize: 16)
                                        ),
                                        actions: [
                                                TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('Annuler')
                                                ),
                                                TextButton(
                                                        onPressed: () {
                                                                Navigator.of(context).pop();
                                                                launchTest();
                                                        },
                                                        child: const Text('Continuer')
                                                )
                                        ]
                                )
                        );
                        return;
                }

                // BIOS-style : liste des différences avec icône, nom, propriété, avant/après
                final List<Widget> diffs = [];
                for (var sensor in ranges.keys) {
                        final current = ranges[sensor]!;
                        final defaults = defaultRanges[sensor]!;
                        for (var k in current.keys) {
                                final def = defaults[k]!;
                                final cur = current[k]!;
                                if (def != cur) {
                                        diffs.add(
                                                TestDiffRow(
                                                        iconPath: k.svgLogo,
                                                        propertyName: '${tr(k.name)} (${getUnitForHeader(k.header)})',
                                                        sensorName: tr(sensor.title ?? ''),
                                                        before: '${def.start.toInt()} / ${def.end.toInt()}',
                                                        after: '${cur.start.toInt()} / ${cur.end.toInt()}'
                                                )
                                        );
                                }
                        }
                }

                showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                        CustomPopup(
                                title: 'Changements détectés',
                                content: diffs.isEmpty
                                        ? const Text(
                                                'Aucun changement', style: TextStyle(color: Colors.white))
                                        : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                        ...diffs
                                                ]
                                        ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('Annuler')
                                        ),
                                        TextButton(
                                                onPressed: () {
                                                        Navigator.of(context).pop();
                                                        launchTest();
                                                },
                                                child: const Text('Continuer')
                                        )
                                ]
                        )
                );
        }

        void onNewIteration() {
                final newIt = widget.iterationNotifier.value;
                if (newIt > lastIteration) {
                        lastIteration = newIt;
                        detectAnomalies();
                }
        }

        String generateCsv() {
                final rows = <List<dynamic>>[
                        ['Timestamp', 'Capteur', 'Propriété', 'Attendu', 'Reçu']
                ];
                for (final a in anomalyLog) {
                        final ts = a.timestamp;
                        final stamp = '${ts.hour.toString().padLeft(2, '0')}:'
                                '${ts.minute.toString().padLeft(2, '0')}:'
                                '${ts.second.toString().padLeft(2, '0')} '
                                '${ts.day.toString().padLeft(2, '0')}/'
                                '${ts.month.toString().padLeft(2, '0')}/'
                                '${ts.year}';
                        rows.add([stamp, a.sensorName, a.propertyName, a.minMax, a.value]);
                }
                return const ListToCsvConverter().convert(rows);
        }

        Future<File> saveCsvFile(String content) async {
                if (await Permission.storage.request().isDenied) {
                        throw 'Permission stockage refusée';
                }
                final dir = await getExternalStorageDirectory();
                final time = DateTime.now().millisecondsSinceEpoch;
                final path = '${dir!.path}/Test_$time.csv';
                final file = File(path);
                return file.writeAsString(content);
        }

        Future<void> _exportLogs() async {
                final csv = generateCsv();
                try {
                        final file = await saveCsvFile(csv);
                        // Partage des fichiers via le share de SharePlus
                        await SharePlus.instance.share(
                                ShareParams(
                                        text: 'Logs d’anomalies du test',
                                        files: [XFile(file.path)]
                                )
                        );
                }
                catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur export : $e'))
                        );
                }
        }

        void detectAnomalies() {
                for (var sensor in ranges.keys) {
                        final currentRanges = ranges[sensor]!;
                        final realVals = RealValuesHolder().realValues[sensor] ?? {};
                        for (var k in currentRanges.keys) {
                                final range = currentRanges[k]!;
                                final real = realVals[k];
                                if (real != null && (real < range.start || real > range.end)) {
                                        setState(
                                                () {
                                                        anomalyLog.add(
                                                                AnomalyRow(
                                                                        sensorName: '${tr(sensor.title ?? '')} (${tr(sensor.placement ?? '')})',
                                                                        propertyName: tr(k.name),
                                                                        value: '${real.toStringAsFixed(1)} ${getUnitForHeader(k.header)}',
                                                                        minMax: '(${range.start.toInt()} : ${range.end.toInt()})',
                                                                        timestamp: DateTime.now()
                                                                )
                                                        );
                                                }
                                        );
                                }
                        }
                }
        }

        // Ajoute une méthode utilitaire pour retrouver le DataMap à partir du nom de propriété
        DataMap? findDataMapByName(String propertyName) {
                for (final sensor in ranges.keys) {
                        for (final key in sensor.data.keys) {
                                if (tr(key.name) == propertyName || key.name == propertyName) {
                                        return key;
                                }
                        }
                }
                return null;
        }

        // Mets à jour anomalyBiosList pour utiliser le svgLogo du DataMap
        Widget anomalyBiosList(List<AnomalyRow> anomalies) {
                return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: anomalies.map((a) {
                                        final dataMap = findDataMapByName(a.propertyName);
                                        final iconPath = dataMap?.svgLogo ?? microchip;
                                        return AnomalyBiosRow(
                                                iconPath: iconPath,
                                                sensorName: a.sensorName,
                                                propertyName: a.propertyName,
                                                expected: a.minMax,
                                                actual: a.value,
                                                timestamp: a.timestamp
                                        );
                                }
                        ).toList()
                );
        }

        Widget buildLogScreen() {
                final now = DateTime.now();
                final timestampStr = ''
                        '${now.hour.toString().padLeft(2, '0')}:'
                        '${now.minute.toString().padLeft(2, '0')} '''
                        '${now.day.toString().padLeft(2, '0')}/'
                        '${now.month.toString().padLeft(2, '0')}/'
                        '${now.year}';

                return Scaffold(
                        backgroundColor: backgroundColor,
                        body: SafeArea(
                                child: Column(
                                        children: [
                                                const SizedBox(height: defaultPadding / 2),
                                                Text('TEST STARTED', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                                const SizedBox(height: defaultPadding / 2),
                                                Text(timestampStr, style: const TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
                                                const SizedBox(height: defaultPadding / 2),

                                                if (anomalyLog.isNotEmpty) ...[
                                                        Text(
                                                                'ANOMALIES DÉTECTÉES [${anomalyLog.length}]',
                                                                style: const TextStyle(
                                                                        fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                                                                textAlign: TextAlign.center
                                                        ),

                                                        const SizedBox(height: defaultPadding / 2)
                                                ],
                                                Expanded(
                                                        child: SingleChildScrollView(
                                                                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                                                                child: anomalyBiosList(
                                                                        anomalyLog.length > 10
                                                                                ? anomalyLog.sublist(anomalyLog.length - 10)
                                                                                : anomalyLog
                                                                )
                                                        )
                                                ),
                                                Padding(
                                                        padding: const EdgeInsets.all(defaultPadding),
                                                        child: SizedBox(
                                                                width: double.infinity,
                                                                height: 48,
                                                                child: ElevatedButton.icon(
                                                                        onPressed: stopTest,
                                                                        icon: const Icon(Icons.stop, color: Colors.white),
                                                                        label: const Text(
                                                                                'Arrêter Test', style: TextStyle(color: Colors.white)),
                                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red)
                                                                )
                                                        )
                                                )
                                        ]
                                )
                        )
                );
        }
}



class AnomalyRow {
        final String sensorName;
        final String propertyName;
        final String value;
        final String minMax;
        final DateTime timestamp;
        AnomalyRow({
                required this.sensorName,
                required this.propertyName,
                required this.value,
                required this.minMax,
                required this.timestamp
        });
}

// Widget BIOS-style pour une anomalie
class AnomalyBiosRow extends StatelessWidget {
        final String iconPath;
        final String sensorName;
        final String propertyName;
        final String expected;
        final String actual;
        final DateTime timestamp;

        const AnomalyBiosRow({
                required this.iconPath,
                required this.sensorName,
                required this.propertyName,
                required this.expected,
                required this.actual,
                required this.timestamp,
                Key? key
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                                children: [
                                        SvgPicture.asset(iconPath, width: 28, height: 28, colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                Text(sensorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                Row(
                                                                        children: [
                                                                                Text(propertyName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                                                                const SizedBox(width: 8),
                                                                                Text(
                                                                                        DateFormat('HH:mm  dd/MM/yyyy').format(timestamp),
                                                                                        style: const TextStyle(color: Colors.white38, fontSize: 12)
                                                                                )
                                                                        ]
                                                                )
                                                        ]
                                                )
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                        Text('Attendu: $expected', style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                                                        Text('Reçu: $actual', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))
                                                ]
                                        )
                                ]
                        )
                );
        }
}



// Widget popup réutilisable
class RangePopup extends StatefulWidget {
        final SensorsData sensor;
        final Map<DataMap, RangeValues> defaults;
        final Map<DataMap, RangeValues> currents;
        final void Function(Map<DataMap, RangeValues>) onApply;

        const RangePopup({
                required this.sensor,
                required this.defaults,
                required this.currents,
                required this.onApply
        });

        @override
        State<RangePopup> createState() => RangePopupState();
}

class RangePopupState extends State<RangePopup> {
        late Map<DataMap, TextEditingController> controllersMin;
        late Map<DataMap, TextEditingController> controllersMax;
        late Map<DataMap, RangeValues> appliedValues;

        String? rangeError;

        @override
        void initState() {
                super.initState();
                controllersMin = {};
                controllersMax = {};
                for (var key in widget.currents.keys) {
                        controllersMin[key] = TextEditingController(text: widget.currents[key]!.start.toInt().toString());
                        controllersMax[key] = TextEditingController(text: widget.currents[key]!.end.toInt().toString());
                }
                appliedValues = Map<DataMap, RangeValues>.from(widget.currents);
        }

        bool hasRangeChangesAndValid() {
                rangeError = null;
                for (var key in widget.currents.keys) {
                        final min = int.tryParse(controllersMin[key]!.text) ?? widget.defaults[key]!.start.toInt();
                        final max = int.tryParse(controllersMax[key]!.text) ?? widget.defaults[key]!.end.toInt();
                        if (!isRangeValid(key, min, max)) {
                                rangeError = "Le min max pas respecté";
                                return false;
                        }
                        final value = RangeValues(min.toDouble(), max.toDouble());
                        if (appliedValues[key] != value) return true;
                }
                return true;
        }

        bool isRangeValid(DataMap key, int min, int max) {
                final sensorHeader = widget.sensor.header;
                final minMax = minMaxRanges[sensorHeader]?[key.header];
                if (minMax == null) return true;
                return min >= minMax.start && max <= minMax.end && min <= max;
        }

        Widget buildRangeField({
                required String label,
                required TextEditingController controller,
                required DataMap key,
                required bool Function(DataMap, int, int) isRangeValid,
                required TextEditingController minController,
                required TextEditingController maxController,
                required VoidCallback onChanged,
                required String unit
        }) {
                final min = int.tryParse(minController.text) ?? 0;
                final max = int.tryParse(maxController.text) ?? 0;
                final invalid = !isRangeValid(key, min, max);

                return Expanded(
                        child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                        TextField(
                                                controller: controller,
                                                decoration: InputDecoration(
                                                        labelText: label,
                                                        labelStyle: TextStyle(
                                                                color: invalid ? Colors.red : Colors.white70,
                                                                fontWeight: invalid ? FontWeight.bold : FontWeight.normal
                                                        ),
                                                        enabledBorder: UnderlineInputBorder(
                                                                borderSide: BorderSide(
                                                                        color: invalid ? Colors.red : Colors.white38
                                                                )
                                                        ),
                                                        contentPadding: const EdgeInsets.only(right: 40)
                                                ),
                                                style: TextStyle(
                                                        color: invalid ? Colors.red : Colors.white,
                                                        fontWeight: invalid ? FontWeight.bold : FontWeight.normal
                                                ),
                                                keyboardType: TextInputType.number,
                                                onChanged: (_) => onChanged()
                                        ),
                                        Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Text(
                                                        unit,
                                                        style: const TextStyle(color: Colors.white70, fontSize: 14)
                                                )
                                        )
                                ]
                        )
                );
        }

        @override
        Widget build(BuildContext context) {
                // Vérifie la validité globale et prépare le message d’erreur
                bool valid = true;
                for (var key in widget.currents.keys) {
                        final min = int.tryParse(controllersMin[key]!.text) ?? widget.defaults[key]!.start.toInt();
                        final max = int.tryParse(controllersMax[key]!.text) ?? widget.defaults[key]!.end.toInt();
                        if (!isRangeValid(key, min, max)) {
                                valid = false;
                                break;
                        }
                }

                final hasChanged = widget.currents.keys.any((key) {
                                final min = int.tryParse(controllersMin[key]!.text) ?? widget.defaults[key]!.start.toInt();
                                final max = int.tryParse(controllersMax[key]!.text) ?? widget.defaults[key]!.end.toInt();
                                final value = RangeValues(min.toDouble(), max.toDouble());
                                return appliedValues[key] != value;
                        }
                );

                return CustomPopup(
                        title: tr(widget.sensor.title ?? ''),
                        content: SingleChildScrollView(
                                child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                for (var key in widget.currents.keys)
                                                        Container(
                                                                margin: const EdgeInsets.only(bottom: 12, right: 8),
                                                                padding: const EdgeInsets.all(12),
                                                                decoration: BoxDecoration(
                                                                        color: Colors.white10,
                                                                        borderRadius: BorderRadius.circular(8)
                                                                ),
                                                                child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                                Row(
                                                                                        children: [
                                                                                                SvgPicture.asset(
                                                                                                        key.svgLogo,
                                                                                                        height: 24,
                                                                                                        width: 24,
                                                                                                        colorFilter: const ColorFilter.mode(
                                                                                                                Colors.white70,
                                                                                                                BlendMode.srcIn
                                                                                                        )
                                                                                                ),
                                                                                                const SizedBox(width: 8),
                                                                                                Text(
                                                                                                        tr(key.name),
                                                                                                        style: const TextStyle(color: Colors.white70, fontSize: 15)
                                                                                                )
                                                                                        ]
                                                                                ),
                                                                                const SizedBox(height: 8),
                                                                                Row(
                                                                                        children: [
                                                                                                buildRangeField(
                                                                                                        label: 'Min',
                                                                                                        controller: controllersMin[key]!,
                                                                                                        key: key,
                                                                                                        isRangeValid: isRangeValid,
                                                                                                        minController: controllersMin[key]!,
                                                                                                        maxController: controllersMax[key]!,
                                                                                                        onChanged: () => setState(() {
                                                                                                                }
                                                                                                        ),
                                                                                                        unit: getUnitForHeader(key.header)
                                                                                                ),
                                                                                                const SizedBox(width: 12),
                                                                                                buildRangeField(
                                                                                                        label: 'Max',
                                                                                                        controller: controllersMax[key]!,
                                                                                                        key: key,
                                                                                                        isRangeValid: isRangeValid,
                                                                                                        minController: controllersMin[key]!,
                                                                                                        maxController: controllersMax[key]!,
                                                                                                        onChanged: () => setState(() {
                                                                                                                }
                                                                                                        ),
                                                                                                        unit: getUnitForHeader(key.header)
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        ]
                                                                )
                                                        ),
                                                if (!valid)
                                                Padding(
                                                        padding: const EdgeInsets.only(bottom: 8),
                                                        child: Text(
                                                                "Le min max pas respecté",
                                                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                                                        )
                                                ),
                                                ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                        onPressed: () {
                                                                setState(() {
                                                                                widget.defaults.forEach((key, value) {
                                                                                                controllersMin[key]!.text = value.start.toInt().toString();
                                                                                                controllersMax[key]!.text = value.end.toInt().toString();
                                                                                        }
                                                                                );
                                                                        }
                                                                );
                                                        },
                                                        child: const Text('Reset defaults')
                                                )
                                        ]
                                )
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel')
                                ),
                                TextButton(
                                        onPressed: (valid && hasChanged)
                                                ? () {
                                                        setState(() {
                                                                        for (var key in widget.currents.keys) {
                                                                                final min = int.tryParse(controllersMin[key]!.text) ?? widget.defaults[key]!.start.toInt();
                                                                                final max = int.tryParse(controllersMax[key]!.text) ?? widget.defaults[key]!.end.toInt();
                                                                                widget.currents[key] = RangeValues(min.toDouble(), max.toDouble());
                                                                        }
                                                                        appliedValues
                                                                        ..clear()
                                                                        ..addAll(widget.currents);
                                                                        widget.onApply(widget.currents);
                                                                        Navigator.of(context).pop();
                                                                }
                                                        );
                                                }
                                                : null,
                                        child: const Text('Apply')
                                )
                        ]
                );
        }
}



class TestDiffRow extends StatelessWidget {
        final String iconPath;
        final String propertyName;
        final String sensorName;
        final String before;
        final String after;

        const TestDiffRow({
                required this.iconPath,
                required this.propertyName,
                required this.sensorName,
                required this.before,
                required this.after,
                Key? key
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                                children: [
                                        SvgPicture.asset(iconPath, width: 28, height: 28, colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                Text(sensorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                Text(propertyName, style: const TextStyle(color: Colors.white70, fontSize: 13))
                                                        ]
                                                )
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                        Container(
                                                                margin: const EdgeInsets.only(right: 10),
                                                                child: Text('Défaut: $before', style: const TextStyle(color: Colors.white54, fontSize: 13))
                                                        ),
                                                        Container(
                                                                margin: const EdgeInsets.only(right: 10),
                                                                child: Text('Setté: $after', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13))
                                                        )
                                                ]
                                        )
                                ]
                        )
                );
        }
}