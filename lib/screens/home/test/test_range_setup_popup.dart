import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

class TestRangeSetupPopup extends StatefulWidget {
        final SensorsData sensor;
        final Map<DataMap, RangeValues> defaults;
        final Map<DataMap, RangeValues> currents;
        final void Function(Map<DataMap, RangeValues>) onApply;

        const TestRangeSetupPopup({
                required this.sensor,
                required this.defaults,
                required this.currents,
                required this.onApply
        });

        @override
        State<TestRangeSetupPopup> createState() => TestRangeSetupPopupState();
}

class TestRangeSetupPopupState extends State<TestRangeSetupPopup> {
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

                final hasChanged = widget.currents.keys.any(
                        (key) {
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
                                        onPressed: (valid && hasChanged)
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