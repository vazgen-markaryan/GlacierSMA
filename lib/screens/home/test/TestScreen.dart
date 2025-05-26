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
        State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
        // Pour chaque capteur, une map DataMap -> RangeValues
        final Map<SensorsData, Map<DataMap, RangeValues>> ranges = {};
        final Map<SensorsData, Map<DataMap, RangeValues>> defaultRanges = {};
        final List<String> logs = [];
        bool isTesting = false;

        @override
        void initState() {
                super.initState();
                final m = widget.activeMaskNotifier.value ?? 0;
                // Initialiser defaults 10/10 par DataMap (utilise int pour affichage)
                for (var s in widget.getSensors(SensorType.internal) + widget.getSensors(SensorType.modbus)) {
                        if (!_isActive(s, m)) continue;
                        final dm = <DataMap, RangeValues>{};
                        for (var key in s.data.keys) {
                                dm[key] = const RangeValues(10, 10);
                        }
                        defaultRanges[s] = Map.of(dm);
                        ranges[s] = Map.of(dm);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => _showIntroDialog());
        }

        bool _isActive(SensorsData s, int m) {
                final h = s.header?.toLowerCase();
                if (h == 'gps_status' || h == 'iridium_status' || h == 'sdcard' || s.dataProcessor != null) return false;
                if (s.bitIndex != null && (m & (1 << s.bitIndex!)) == 0) return false;
                return true;
        }

        void _showIntroDialog() {
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

        void _showRangeDialog(SensorsData sensor) {
                final defaults = defaultRanges[sensor]!;
                final currents = ranges[sensor]!;
                final controllersMin = <DataMap, TextEditingController>{};
                final controllersMax = <DataMap, TextEditingController>{};
                for (var key in currents.keys) {
                        controllersMin[key] = TextEditingController(text: currents[key]!.start.toInt().toString());
                        controllersMax[key] = TextEditingController(text: currents[key]!.end.toInt().toString());
                }
                showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => StatefulBuilder(
                                builder: (ctx, sb) => CustomPopup(
                                        title: sensor.title ?? '',
                                        content: SingleChildScrollView(
                                                child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                                for (var key in currents.keys) ...[
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
                                                                                                                                        onChanged: (_) => sb(() {
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
                                                                                                                                        onChanged: (_) => sb(() {
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
                                                                                sb(() {
                                                                                                defaults.forEach((k, v) => currents[k] = v);
                                                                                                for (var key in controllersMin.keys) {
                                                                                                        controllersMin[key]!.text = defaults[key]!.start.toInt().toString();
                                                                                                        controllersMax[key]!.text = defaults[key]!.end.toInt().toString();
                                                                                                }
                                                                                        }
                                                                                );
                                                                                setState(() => ranges[sensor] = Map.of(defaults));
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
                                                        onPressed: () {
                                                                sb(() {
                                                                                for (var key in currents.keys) {
                                                                                        final min = int.tryParse(controllersMin[key]!.text) ?? defaults[key]!.start.toInt();
                                                                                        final max = int.tryParse(controllersMax[key]!.text) ?? defaults[key]!.end.toInt();
                                                                                        currents[key] = RangeValues(min.toDouble(), max.toDouble());
                                                                                }
                                                                                ranges[sensor] = Map.of(currents);
                                                                        }
                                                                );
                                                                Navigator.of(context).pop();
                                                        },
                                                        child: const Text('Apply')
                                                )
                                        ]
                                )
                        )
                );
        }

        bool get _hasChanges {
                for (var s in ranges.keys) {
                        final curr = ranges[s]!;
                        final def = defaultRanges[s]!;
                        if (curr.length != def.length) return true;
                        for (var k in curr.keys) {
                                if (curr[k] != def[k]) return true;
                        }
                }
                return false;
        }

        void _launchTest() {
                setState(() => isTesting = true);
                logs.clear();
                logs.add('Test started');
        }

        void _stopTest() {
                setState(() => isTesting = false);
                logs.add('Test stopped');
        }

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        body: isTesting ? _buildLogScreen() : _buildConfigScreen()
                );
        }

        Widget _buildConfigScreen() {
                final m = widget.activeMaskNotifier.value ?? 0;
                final internal = widget.getSensors(SensorType.internal).where((s) => _isActive(s, m));
                final modbus = widget.getSensors(SensorType.modbus).where((s) => _isActive(s, m));
                final children = <Widget>[];
                if (internal.isNotEmpty) {
                        children.add(const Text('Internal Sensors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
                        for (var s in internal) {
                                children.add(Padding(
                                                padding: const EdgeInsets.only(bottom: defaultPadding),
                                                child: SensorCard(sensor: s, testMode: true, onTap: () => _showRangeDialog(s))
                                        ));
                        }
                }
                if (modbus.isNotEmpty) {
                        children.add(const Text('ModBus Sensors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
                        for (var s in modbus) {
                                children.add(Padding(
                                                padding: const EdgeInsets.only(bottom: defaultPadding),
                                                child: SensorCard(sensor: s, testMode: true, onTap: () => _showRangeDialog(s))
                                        ));
                        }
                }
                // Bouton lancement en bas
                children.add(const SizedBox(height: defaultPadding * 2));
                children.add(SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                        onPressed: _hasChanges ? _launchTest : null,
                                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                                        label: const Text('Lancer Test', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                                backgroundColor: _hasChanges ? Theme.of(context).primaryColor : Colors.grey
                                        )
                                )
                        ));

                return SingleChildScrollView(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(children: children)
                );
        }

        Widget _buildLogScreen() {
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
                                                        onPressed: _stopTest,
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