import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_anomaly_row.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_sensor_diff_row.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_feeder.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_range_setup_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';

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

        @override
        void initState() {
                super.initState();

                // (1) Dès que l’écran est monté, on requiert la permission au runtime
                WidgetsBinding.instance.addPostFrameCallback(
                        (_) async {
                                final granted = await requestAppropriatePermission(context);
                                if (!granted) {
                                        // Permission refusée → on affiche un popup expliquant comment aller dans les Paramètres
                                        await showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) => CustomPopup(
                                                        title: 'Permission requise',
                                                        content: const Text(
                                                                'L’accès aux fichiers est nécessaire pour pouvoir enregistrer vos logs.\n'
                                                                'Allez dans “Paramètres → Applications → Glacier SMA → Permissions” '
                                                                'et activez “Accès au stockage” ou “Accès à tous les fichiers” selon votre version Android.',
                                                                style: TextStyle(color: Colors.white)
                                                        ),
                                                        actions: [
                                                                TextButton(
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                        child: const Text('OK')
                                                                )
                                                        ]
                                                )
                                        );
                                        // On ne quitte PAS TestScreen ici, on reste bloqué sur l’écran de config.
                                        return;
                                }

                                // (2) Si la permission est accordée, on affiche le tutoriel / intro
                                showIntroDialog(context);
                        }
                );

                // (3) Initialisation normale des ranges/defaultRanges
                final mask = widget.activeMaskNotifier.value ?? 0;
                widget.iterationNotifier.addListener(onNewIteration);

                for (var sensor in widget.getSensors(SensorType.internal) +
                        widget.getSensors(SensorType.modbus)) {
                        if (!shouldIncludeSensor(sensor, mask)) continue;
                        final dataMap = <DataMap, RangeValues>{};
                        for (var key in sensor.data.keys) {
                                if (!shouldIncludeDataMap(sensor, key)) continue;
                                dataMap[key] = getMinMax(sensor, key);
                        }
                        dataMapMinMax[sensor] = dataMap;
                        defaultRanges[sensor] = Map.of(dataMap);
                        ranges[sensor] = Map.of(dataMap);
                }
        }

        @override
        void dispose() {
                widget.iterationNotifier.removeListener(onNewIteration);
                super.dispose();
        }

        void showRangeDialog(SensorsData sensor) {
                showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: '',
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (_, __, ___) =>
                        TestRangeSetupPopup(
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
                setState(
                        () {
                                isTesting = true;
                                logs.clear();
                                anomalyLog.clear();
                                lastIteration = 0;
                        }
                );
        }

        void stopTest() {
                setState(() => isTesting = false);
                showExportConfirmation(context, anomalyLog);
        }

        @override
        Widget build(BuildContext context) {
                return WillPopScope(
                        // On empêche la navigation si le test est en cours
                        onWillPop: () async {
                                if (isTesting) {
                                        showCustomSnackBar(
                                                context,
                                                message: "Arrêtez d’abord le test",
                                                iconData: Icons.warning,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                iconColor: Colors.white
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

        Widget buildLogScreen() {
                final now = DateTime.now();
                final timestampStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

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
                                                                child: anomalyBIOSList(
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
                                                        label: const Text('Lancer Test', style: TextStyle(color: Colors.white)),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor)
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
                                                'Vous runnez le test avec les valeurs par défaut?',
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
                                                TestSensorDiffRow(
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

        Widget anomalyBIOSList(List<AnomalyRow> anomalies) {
                return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: anomalies.map(
                                (anomaly) {
                                        final dataMap = findDataMapByName(anomaly.propertyName);
                                        final iconPath = dataMap?.svgLogo ?? microchip;
                                        return AnomalyBIOSRow(
                                                iconPath: iconPath,
                                                sensorName: anomaly.sensorName,
                                                propertyName: anomaly.propertyName,
                                                expected: anomaly.minMax,
                                                actual: anomaly.value,
                                                timestamp: anomaly.timestamp
                                        );
                                }
                        ).toList()
                );
        }
}