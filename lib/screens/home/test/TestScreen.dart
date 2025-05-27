import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

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

        @override
        void initState() {
                super.initState();
                final mask = widget.activeMaskNotifier.value ?? 0;

                for (var sensor in widget.getSensors(SensorType.internal) + widget.getSensors(SensorType.modbus)) {
                        if (!isActive(sensor, mask)) continue;
                        final dataMap = <DataMap, RangeValues>{};
                        for (var key in sensor.data.keys) {
                                dataMap[key] = getMinMax(sensor, key);
                        }
                        dataMapMinMax[sensor] = dataMap;
                        defaultRanges[sensor] = Map.of(dataMap);
                        ranges[sensor] = Map.of(dataMap);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => showIntroDialog());
        }

        RangeValues getMinMax(SensorsData sensor, DataMap key) {
                if (sensor.header == "bme280_status" && key.header == "bme280_temperature") {
                        return const RangeValues(-40, 85);
                }
                else if (sensor.header == "bme280_status" && key.header == "bme280_pression") {
                        return const RangeValues(300, 1100);
                }
                else if (sensor.header == "bme280_status" && key.header == "bme280_humidity") {
                        return const RangeValues(0, 100);
                }
                else if (sensor.header == "bme280_status" && key.header == "bme280_altitude") {
                        return const RangeValues(0, 10000);
                }
                return const RangeValues(10, 10);
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

        List<Widget> buildSensorList(Iterable<SensorsData> sensors, String title) {
                if (sensors.isEmpty) return [];
                return [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ...sensors.map((sensor) => Padding(
                                        padding: const EdgeInsets.only(bottom: defaultPadding),
                                        child: SensorCard(sensor: sensor, testMode: true, onTap: () => showRangeDialog(sensor))
                                ))
                ];
        }

        Widget buildConfigScreen() {
                final mask = widget.activeMaskNotifier.value ?? 0;
                final internal = widget.getSensors(SensorType.internal).where((sensor) => isActive(sensor, mask));
                final modbus = widget.getSensors(SensorType.modbus).where((sensor) => isActive(sensor, mask));

                return SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                                children: [
                                        ...buildSensorList(internal, 'Internal Sensors'),
                                        ...buildSensorList(modbus, 'ModBus Sensors'),
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
                        title: widget.sensor.title ?? '',
                        content: SingleChildScrollView(
                                child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                for (var key in widget.currents.keys) ...[
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
                                                                                                                key.header,
                                                                                                                style: const TextStyle(color: Colors.white70, fontSize: 15)
                                                                                                        )
                                                                                                ]
                                                                                        ),
                                                                                        const SizedBox(height: 8),
                                                                                        Row(
                                                                                                children: [
                                                                                                        Expanded(
                                                                                                                child: TextField(
                                                                                                                        controller: controllersMin[key],
                                                                                                                        decoration: const InputDecoration(
                                                                                                                                labelText: 'Min',
                                                                                                                                labelStyle: TextStyle(color: Colors.white70),
                                                                                                                                enabledBorder: UnderlineInputBorder(
                                                                                                                                        borderSide: BorderSide(color: Colors.white38)
                                                                                                                                )
                                                                                                                        ),
                                                                                                                        style: const TextStyle(color: Colors.white),
                                                                                                                        keyboardType: TextInputType.number,
                                                                                                                        onChanged: (_) => setState(() {
                                                                                                                                }
                                                                                                                        )
                                                                                                                )
                                                                                                        ),
                                                                                                        const SizedBox(width: 12),
                                                                                                        Expanded(
                                                                                                                child: TextField(
                                                                                                                        controller: controllersMax[key],
                                                                                                                        decoration: const InputDecoration(
                                                                                                                                labelText: 'Max',
                                                                                                                                labelStyle: TextStyle(color: Colors.white70),
                                                                                                                                enabledBorder: UnderlineInputBorder(
                                                                                                                                        borderSide: BorderSide(color: Colors.white38)
                                                                                                                                )
                                                                                                                        ),
                                                                                                                        style: const TextStyle(color: Colors.white),
                                                                                                                        keyboardType: TextInputType.number,
                                                                                                                        onChanged: (_) => setState(() {
                                                                                                                                }
                                                                                                                        )
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
                                        onPressed: hasRangeChanges()
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