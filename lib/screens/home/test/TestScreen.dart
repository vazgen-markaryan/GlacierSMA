import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_group_factory.dart';

/// Écran de test en environnement contrôlé
class TestScreen extends StatefulWidget {
        final ValueListenable<int?> activeMaskNotifier;
        final List<SensorsData> Function(SensorType) getSensors;

        const TestScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.getSensors
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

                for (var sensor in widget.getSensors(SensorType.internal) + widget.getSensors(SensorType.modbus)) {
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

        RangeValues getMinMax(SensorsData sensor, DataMap key) {
                return minMaxRanges[sensor.header]?[key.header] ?? const RangeValues(0, 999999);
        }

        bool isActive(SensorsData sensor, int mask) {
                final header = sensor.header?.toLowerCase();
                if (header == 'gps_status' || header == 'iridium_status' || header == 'sdcard' || sensor.dataProcessor != null) return false;
                if (sensor.bitIndex != null && (mask & (1 << sensor.bitIndex!)) == 0) return false;
                return true;
        }

        void showIntroDialog() {
                showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CustomPopup(
                                title: 'Environnement contrôlé',
                                content: const Text('Tutoriel placeholder'),
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
                        pageBuilder: (_, __, ___) => RangePopup(
                                sensor: sensor,
                                defaults: defaultRanges[sensor]!,
                                currents: ranges[sensor]!,
                                onApply: (updated) => setState(() => ranges[sensor] = Map.of(updated))
                        ),
                        transitionBuilder: (context, animation, _, child) => Transform.scale(
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
                setState(() => isTesting = true);
                logs.clear();
                logs.add('Test started');
        }

        void stopTest() {
                setState(() => isTesting = false);
                logs.add('Test stopped');
        }

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        body: isTesting ? buildLogScreen() : buildConfigScreen()
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
                                                showDataProcessors: false,
                                                testMode: true
                                        ),

                                        const SizedBox(height: defaultPadding),

                                        SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                        onPressed: hasChanges ? launchTest : null,
                                                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                        label: const Text('Lancer Test', style: TextStyle(color: Colors.white)),
                                                        style: ElevatedButton.styleFrom(
                                                                backgroundColor: hasChanges ? Theme.of(context).primaryColor : Colors.grey
                                                        )
                                                )
                                        )
                                ]
                        )
                );
        }

        Widget buildLogScreen() {
                return Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        const Text('Test running'),
                                        const SizedBox(height: 8),
                                        Expanded(
                                                child: ListView.builder(
                                                        itemCount: logs.length,
                                                        itemBuilder: (_, i) => Text(logs[i])
                                                )
                                        ),
                                        const SizedBox(height: defaultPadding),

                                        // Bouton Stop
                                        SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                        onPressed: stopTest,
                                                        icon: const Icon(Icons.stop, color: Colors.white),
                                                        label: const Text('Arrêter Test', style: TextStyle(color: Colors.white)),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red)
                                                )
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

        bool hasRangeChanges() {
                for (var key in widget.currents.keys) {
                        final min = int.tryParse(controllersMin[key]!.text) ?? widget.defaults[key]!.start.toInt();
                        final max = int.tryParse(controllersMax[key]!.text) ?? widget.defaults[key]!.end.toInt();
                        final value = RangeValues(min.toDouble(), max.toDouble());
                        if (appliedValues[key] != value) return true;
                }
                return false;
        }

        @override
        Widget build(BuildContext context) {
                return CustomPopup(
                        title: tr(widget.sensor.title ?? ''),
                        content: SingleChildScrollView(
                                child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                for (var key in widget.currents.keys)
                                                        ...[
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
                                                                                                        Expanded(
                                                                                                                child: Stack(
                                                                                                                        alignment: Alignment.centerRight,
                                                                                                                        children: [
                                                                                                                                TextField(
                                                                                                                                        controller: controllersMin[key],
                                                                                                                                        decoration: const InputDecoration(
                                                                                                                                                labelText: 'Min',
                                                                                                                                                labelStyle: TextStyle(color: Colors.white70),
                                                                                                                                                enabledBorder: UnderlineInputBorder(
                                                                                                                                                        borderSide: BorderSide(color: Colors.white38)
                                                                                                                                                ),
                                                                                                                                                contentPadding: EdgeInsets.only(right: 40)
                                                                                                                                        ),
                                                                                                                                        style: const TextStyle(color: Colors.white),
                                                                                                                                        keyboardType: TextInputType.number,
                                                                                                                                        onChanged: (_) => setState(() {
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                ),
                                                                                                                                Padding(
                                                                                                                                        padding: const EdgeInsets.only(right: 8),
                                                                                                                                        child: Text(
                                                                                                                                                getUnitForHeader(key.header),
                                                                                                                                                style: const TextStyle(color: Colors.white70, fontSize: 14)
                                                                                                                                        )
                                                                                                                                )
                                                                                                                        ]
                                                                                                                )
                                                                                                        ),
                                                                                                        const SizedBox(width: 12),
                                                                                                        Expanded(
                                                                                                                child: Stack(
                                                                                                                        alignment: Alignment.centerRight,
                                                                                                                        children: [
                                                                                                                                TextField(
                                                                                                                                        controller: controllersMax[key],
                                                                                                                                        decoration: const InputDecoration(
                                                                                                                                                labelText: 'Max',
                                                                                                                                                labelStyle: TextStyle(color: Colors.white70),
                                                                                                                                                enabledBorder: UnderlineInputBorder(
                                                                                                                                                        borderSide: BorderSide(color: Colors.white38)
                                                                                                                                                ),
                                                                                                                                                contentPadding: EdgeInsets.only(right: 40)
                                                                                                                                        ),
                                                                                                                                        style: const TextStyle(color: Colors.white),
                                                                                                                                        keyboardType: TextInputType.number,
                                                                                                                                        onChanged: (_) => setState(() {
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                ),
                                                                                                                                Padding(
                                                                                                                                        padding: const EdgeInsets.only(right: 8),
                                                                                                                                        child: Text(
                                                                                                                                                getUnitForHeader(key.header),
                                                                                                                                                style: const TextStyle(color: Colors.white70, fontSize: 14)
                                                                                                                                        )
                                                                                                                                )
                                                                                                                        ]
                                                                                                                )
                                                                                                        )
                                                                                                ]
                                                                                        )
                                                                                ]
                                                                        )
                                                                )
                                                        ],
                                                ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                        onPressed: () {
                                                                setState(
                                                                        () {
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
                                        onPressed: hasRangeChanges()
                                                ? () {
                                                        setState(
                                                                () {
                                                                        for (var key in widget.currents.keys) {
                                                                                final min = int.tryParse(controllersMin[key]!.text) ?? widget.defaults[key]!.start.toInt();
                                                                                final max = int.tryParse(controllersMax[key]!.text) ?? widget.defaults[key]!.end.toInt();
                                                                                widget.currents[key] = RangeValues(min.toDouble(), max.toDouble());
                                                                        }
                                                                        appliedValues
                                                                        ..clear()
                                                                        ..addAll(widget.currents);
                                                                        widget.onApply(widget.currents);
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