import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';

typedef SensorTapCallback = void Function(BuildContext context, SensorsData sensor);

List<Widget> createAllSensorGroups({
        required ValueListenable<int?> maskNotifier,
        required List<SensorsData> Function(SensorType) getSensors,
        required SensorTapCallback onTap,
        bool configMode = false,
        ValueNotifier<int>? localMask,
        bool showInactive = false
}) {
        final sections = [
        {
                'titleKey': 'section.data_processors',
                'groupKey': 'data',
                'emptyActive': 'empty.active.data_processors',
                'emptyInactive': 'empty.inactive.data_processors'
        },
        {
                'titleKey': 'section.internal_sensors',
                'groupKey': 'internal',
                'emptyActive': 'empty.active.internal_sensors',
                'emptyInactive': 'empty.inactive.internal_sensors'
        },
        {
                'titleKey': 'section.modbus_sensors',
                'groupKey': 'modbus',
                'emptyActive': 'empty.active.modbus_sensors',
                'emptyInactive': 'empty.inactive.modbus_sensors'
        }
        ];

        return [
                ValueListenableBuilder<int?>(
                        valueListenable: maskNotifier,
                        builder: (context, mask, _) {
                                final myMask = mask ?? 0;
                                final all = [
                                        ...getSensors(SensorType.internal),
                                        ...getSensors(SensorType.modbus)
                                ];

                                final groups = <String, List<SensorsData>>{
                                        'data':     all.where((sensor) => sensor.dataProcessor?.toLowerCase() == 'true').toList(),
                                        'internal': all.where((sensor) => sensor.bus?.toLowerCase() == 'i2c').toList(),
                                        'modbus':   all.where((sensor) => sensor.bus?.toLowerCase() == 'modbus').toList()
                                };

                                List<SensorsData> filter(List<SensorsData> list) {
                                        return list.where((sensor) {
                                                        if (configMode) return true;
                                                        final isActive = sensor.bitIndex == null
                                                                || (myMask & (1 << sensor.bitIndex!)) != 0;
                                                        return showInactive ? !isActive : isActive;
                                                }
                                        ).toList();
                                }

                                return Column(
                                        children: sections.map((section) {
                                                        final raw = groups[section['groupKey']]!;
                                                        final filtered = filter(raw);
                                                        final emptyKey = showInactive
                                                                ? section['emptyInactive'] as String
                                                                : section['emptyActive']   as String;

                                                        return SensorsGroup(
                                                                title: tr(section['titleKey'] as String),
                                                                sensors: filtered,
                                                                emptyMessage: tr(emptyKey),
                                                                itemBuilder: (context, sensor) {
                                                                        if (configMode) {
                                                                                final bit = sensor.bitIndex!;
                                                                                final on = (localMask!.value & (1 << bit)) != 0;
                                                                                return SensorCard(
                                                                                        sensor: sensor,
                                                                                        configMode: true,
                                                                                        isOn: on,
                                                                                        onToggle: (value) {
                                                                                                localMask.value = value
                                                                                                        ? (localMask.value | (1 << bit))
                                                                                                        : (localMask.value & ~(1 << bit));
                                                                                        }
                                                                                );
                                                                        }
                                                                        else {
                                                                                return SensorCard(
                                                                                        sensor: sensor,
                                                                                        onTap: (sensor.data.isNotEmpty && sensor.title != 'SD Card')
                                                                                                ? () => onTap(context, sensor)
                                                                                                : null
                                                                                );
                                                                        }
                                                                }
                                                        );
                                                }
                                        ).toList()
                                );
                        }
                )
        ];
}
