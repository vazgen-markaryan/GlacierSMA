import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_anomaly.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_sensor_diff_row.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_feeder.dart';
import 'package:rev_glacier_sma_mobile/screens/home/test/test_range_setup_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';

/// Écran de test en environnement contrôlé
/// - Gestion des permissions stockage au démarrage
/// - Préparation des plages (min/max) pour chaque DataMap de chaque capteur actif
/// - Passage en mode “test” : écoute des itérations et détection d’anomalies
/// - Affichage des anomalies en temps réel (10 dernières)
/// - Option d’export CSV à l’arrêt du test

class TestScreen extends StatefulWidget {
        /// Notifier du masque `<active>` pour savoir quels capteurs sont actifs
        final ValueListenable<int?> activeMaskNotifier;

        /// Fonction pour récupérer dynamiquement la liste des capteurs (internal ou modbus)
        final List<SensorsData> Function(SensorType) getSensors;

        /// Notifier de l’itération courante reçue (incrémentée à chaque nouvelle trame `<data>`)
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
        /// Pour chaque capteur, pour chaque DataMap, on stocke la plage min/max choisie
        final Map<SensorsData, Map<DataMap, RangeValues>> ranges = {};

        /// Valeurs “par défaut” de chaque plage (issues de `minMaxRanges` dans constants.dart)
        final Map<SensorsData, Map<DataMap, RangeValues>> defaultRanges = {};

        /// Mêmes données, mais conservées en local : `dataMapMinMax` sert uniquement au calcul initial
        final Map<SensorsData, Map<DataMap, RangeValues>> dataMapMinMax = {};

        /// Liste des logs “bruts” reçus (non utilisée directement ici, mais conservée)
        final List<String> logs = [];

        /// Indique si le “test” est en cours (true) ou si l’on est en mode configuration (false)
        bool isTesting = false;

        /// Récupère la dernière itération traitée pour éviter de retraiter la même
        int lastIteration = 0;

        /// Liste des anomalies détectées depuis le début du test
        final List<AnomalyRow> anomalyLog = [];

        @override
        void initState() {
                super.initState();

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                // Dès que l’écran est monté, on demande la permission adaptée selon l’API
                                final granted = await requestAppropriatePermission(context);
                                if (!granted) {
                                        // Si permission refusée, on affiche un popup expliquant comment l’activer manuellement
                                        await showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) => CustomPopup(
                                                        title: tr("test.permission_needed"),
                                                        content: Text(
                                                                tr("test.permission_needed_description"),
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
                                        // On ne quitte pas TestScreen, on reste bloqué en mode config
                                        return;
                                }
                                // Si la permission est accordée, on affiche le tutoriel / intro
                                showIntroDialog(context);
                        }
                );

                // Initialise les plages min/max pour chaque capteur actif
                final mask = widget.activeMaskNotifier.value ?? 0;

                // On s’abonne à l’itération pour détecter les anomalies plus tard
                widget.iterationNotifier.addListener(onNewIteration);

                // Parcourt tous les capteurs internes + modbus
                for (var sensor in widget.getSensors(SensorType.internal) +
                        widget.getSensors(SensorType.modbus)) {

                        // Exclut les capteurs non actifs ou à exclure
                        if (!shouldIncludeSensor(sensor, mask)) continue;

                        // Prépare une map DataMap → RangeValues pour ce capteur
                        final dataMap = <DataMap, RangeValues>{};

                        for (var key in sensor.data.keys) {
                                // Exclut certains champs via `shouldIncludeDataMap`
                                if (!shouldIncludeDataMap(sensor, key)) continue;

                                // Valeurs par défaut extraites de `minMaxRanges[sensor.header]![key.header]`
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

        /// Ouvre le popup pour configurer la plage (min/max) d’un DataMap pour le [sensor]
        void showRangeDialog(SensorsData sensor) {
                showGeneralDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: '',
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (_, __, ___) => TestRangeSetupPopup(
                                sensor: sensor,
                                defaults: defaultRanges[sensor]!,
                                currents: ranges[sensor]!,
                                onApply: (updated) => setState(() => ranges[sensor] = Map.of(updated))
                        ),
                        transitionBuilder: (context, animation, _, child) =>
                        Transform.scale(
                                scale: Curves.easeOutBack.transform(animation.value),
                                child: child
                        )
                );
        }

        /// Retourne `true` s’il y a au moins un paramètre modifié par rapport aux valeurs par défaut
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

        /// Passe en mode “test”, réinitialise les logs et anomalies
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

        /// Arrête le test et propose d’exporter les logs d’anomalie
        void stopTest() {
                setState(() => isTesting = false);
                showExportConfirmation(context, anomalyLog);
        }

        @override
        Widget build(BuildContext context) {
                return WillPopScope(
                        // Empêche le “retour” si le test est en cours
                        onWillPop: () async {
                                if (isTesting) {
                                        showCustomSnackBar(
                                                context,
                                                message: tr("test.stop_test_warning"),
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
                                // Affiche soit l’écran de log, soit la config selon [isTesting]
                                body: isTesting ? buildLogScreen(anomalyLog, ranges, stopTest, backgroundColor) : buildConfigScreen()
                        )
                );
        }

        /// Construit l’écran affichant l’heure de début, le nombre d’anomalies,
        /// la liste des dernières anomalies (sans scroll interne), puis le bouton “Arrêter Test”.
        /// Le scroll global est géré par SingleChildScrollView.
        Widget buildLogScreen(
                List<AnomalyRow> anomalyLog,
                Map<SensorsData, Map<DataMap, RangeValues>> ranges,
                VoidCallback stopTest,
                Color backgroundColor
        ) {
                final now = DateTime.now();
                final timestampStr =
                        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} "
                        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

                // On affiche au plus les 8 dernières anomalies
                final toShow = anomalyLog.length > 8
                        ? anomalyLog.sublist(anomalyLog.length - 8)
                        : anomalyLog;

                return Scaffold(
                        backgroundColor: backgroundColor,
                        body: SafeArea(
                                child: SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                                        child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                        const SizedBox(height: defaultPadding / 4),

                                                        // 1) Titre “TEST STARTED”
                                                        Text(
                                                                tr("test.test_started"),
                                                                style: const TextStyle(
                                                                        fontSize: 22,
                                                                        fontWeight: FontWeight.bold
                                                                ),
                                                                textAlign: TextAlign.center
                                                        ),

                                                        const SizedBox(height: defaultPadding / 4),

                                                        // 2) Horodatage
                                                        Text(
                                                                timestampStr,
                                                                style: const TextStyle(
                                                                        fontSize: 16,
                                                                        color: Colors.white70
                                                                ),
                                                                textAlign: TextAlign.center
                                                        ),

                                                        const SizedBox(height: defaultPadding / 4),

                                                        // 3) Si on a des anomalies, on affiche “ANOMALIES DÉTECTÉES [n]”
                                                        if (toShow.isNotEmpty) ...[
                                                                Text(
                                                                        tr("test.anomalies_detected") + ' [${anomalyLog.length}]',
                                                                        style: const TextStyle(
                                                                                fontSize: 18,
                                                                                color: Colors.red,
                                                                                fontWeight: FontWeight.bold
                                                                        ),
                                                                        textAlign: TextAlign.center
                                                                ),
                                                                const SizedBox(height: defaultPadding / 2)
                                                        ],

                                                        // 4) Liste des anomalies sans scroll interne
                                                        for (final anomaly in toShow) ...[
                                                                        AnomalyBIOSRow(
                                                                                iconPath: findDataMapByName(anomaly.propertyName, ranges)?.svgLogo ?? microchip,
                                                                                sensorName: anomaly.sensorName,
                                                                                propertyName: anomaly.propertyName,
                                                                                expected: anomaly.minMax,
                                                                                actual: anomaly.value,
                                                                                timestamp: anomaly.timestamp
                                                                        )
                                                                ],

                                                        const SizedBox(height: defaultPadding / 2),

                                                        // 5) Bouton “Arrêter Test” en bas de la page
                                                        Padding(
                                                                padding: const EdgeInsets.only(bottom: defaultPadding),
                                                                child: SizedBox(
                                                                        width: double.infinity,
                                                                        height: 48,
                                                                        child: ElevatedButton.icon(
                                                                                onPressed: stopTest,
                                                                                icon: const Icon(Icons.stop, color: Colors.white),
                                                                                label: Text(
                                                                                        tr("test.stop_test"),
                                                                                        style: const TextStyle(color: Colors.white)
                                                                                ),
                                                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red)
                                                                        )
                                                                )
                                                        )
                                                ]
                                        )
                                )
                        )
                );
        }

        // Fonction interne pour retrouver l’objet DataMap correspondant à `propertyName`
        DataMap? findDataMapByName(
                String propertyName,
                Map<SensorsData, Map<DataMap, RangeValues>> ranges
        ) {
                for (final sensor in ranges.keys) {
                        for (final key in sensor.data.keys) {
                                // Compare le nom localisé (tr(key.name)) ou le header brut
                                if (tr(key.name) == propertyName || key.name == propertyName) {
                                        return key;
                                }
                        }
                }
                return null;
        }

        /// Construit l’écran de configuration :
        /// - Affiche tous les capteurs actifs (via createAllSensorGroups), en “testMode”
        /// - Un bouton “Lancer Test” en bas
        Widget buildConfigScreen() {
                return SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                                children: [
                                        // Reprend les mêmes cartes que sur HomeScreen, mais en cache le graphique (testMode: true)
                                        ...createAllSensorGroups(
                                                maskNotifier: widget.activeMaskNotifier,
                                                getSensors: widget.getSensors,
                                                onTap: (ctx, s) => showRangeDialog(s),
                                                configMode: false,
                                                testMode: true
                                        ),

                                        const SizedBox(height: defaultPadding),

                                        // Bouton “Lancer Test”
                                        SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                        onPressed: () => onLaunchTestPressed(context),
                                                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                        label: Text(
                                                                tr("test.start_test"),
                                                                style: const TextStyle(color: Colors.white)
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                                backgroundColor: Theme.of(context).primaryColor
                                                        )
                                                )
                                        )
                                ]
                        )
                );
        }

        /// Gère la logique avant de lancer le test :
        /// - Si aucune plage n’a été modifiée (hasChanges==false), on confirme qu’on lance “avec défauts”
        /// - Sinon, on affiche d’abord les différences (TestSensorDiffRow) avant de lancer
        void onLaunchTestPressed(BuildContext context) {
                if (!hasChanges) {
                        showConfirmationDialog(context);
                        return;
                }
                showDiffDialog(context);
        }

        /// Affiche un popup de confirmation simple :
        /// “Vous lancez le test avec les valeurs par défaut ?”
        void showConfirmationDialog(BuildContext context) {
                showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CustomPopup(
                                title: tr("test.confirmation"),
                                content: Text(
                                        tr("test.confirmation_description"),
                                        style: const TextStyle(color: Colors.white, fontSize: 16)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: Text(tr("test.cancel"))
                                        ),
                                        TextButton(
                                                onPressed: () {
                                                        Navigator.of(context).pop();
                                                        launchTest();
                                                },
                                                child: Text(tr("test.continue"))
                                        )
                                ]
                        )
                );
        }

        /// Affiche un popup listant toutes les différences entre plages par défaut
        /// et plages modifiées, en utilisant `buildDiffs()` de test_utils.dart
        void showDiffDialog(BuildContext context) {
                final List<Widget> diffs = buildDiffs(ranges, defaultRanges);

                showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CustomPopup(
                                title: tr("test.detected_changes"),
                                content: diffs.isEmpty
                                        ? Text(
                                                tr("test.no_changes"),
                                                style: const TextStyle(color: Colors.white)
                                        )
                                        : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: diffs
                                        ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: Text(tr("test.cancel"))
                                        ),
                                        TextButton(
                                                onPressed: () {
                                                        Navigator.of(context).pop();
                                                        launchTest();
                                                },
                                                child: Text(tr("test.continue"))
                                        )
                                ]
                        )
                );
        }

        /// Appelé à chaque nouvelle valeur de `iterationNotifier`.
        /// Si l’itération a augmenté, on déclenche `detectAnomalies()`
        /// (qui renvoie une liste d’`AnomalyRow` à ajouter à [anomalyLog]).
        void onNewIteration() {
                final newIt = widget.iterationNotifier.value;
                if (newIt > lastIteration) {
                        lastIteration = newIt;
                        final newAnomalies =
                                detectAnomalies(ranges, RealValuesHolder().realValues);
                        if (newAnomalies.isNotEmpty) {
                                setState(() {
                                                anomalyLog.addAll(newAnomalies);
                                        }
                                );
                        }
                }
        }
}