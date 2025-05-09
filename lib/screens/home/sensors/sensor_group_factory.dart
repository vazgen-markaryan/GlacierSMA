import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';

typedef SensorTapCallback = void Function(BuildContext context, SensorsData sensor);

/// Crée les 3 groupes de capteurs (Data Processors / Internes / ModBus) et renvoie une liste de Widgets à insérer dans un Column.
/// - [maskNotifier] pilote l’affichage des capteurs actifs (ou tous en mode config).
/// - [getSensors] doit renvoyer la liste de `SensorsData` pour chaque SensorType.
/// - [onTap] appelé en mode normal quand on clique sur une carte.
/// - [configMode] = true pour générer les groupes en configuration (avec switch).
/// - [localMask] nécessaire si [configMode]==true, pour gérer les toggles.
/// - [showInactive] = true pour afficher les capteurs inactifs (pour le debug).

List<Widget> createAllSensorGroups({
        required ValueListenable<int?> maskNotifier,
        required List<SensorsData> Function(SensorType) getSensors,
        required SensorTapCallback onTap,
        bool configMode = false,
        ValueNotifier<int>? localMask,
        bool showInactive = false
}) {
        // Définit pour chaque section son titre, sa clé de grouping, son message “vide” en mode actif et en mode inactif.
        const sections = [
        {
                'title': 'PROCESSEURS DE DONNÉES',
                'key': 'data',
                'emptyActive':   'Aucun Data Processor Actif.',
                'emptyInactive': 'Aucun Data Processor Inactif.'
        },
        {
                'title': 'CAPTEURS INTERNES',
                'key': 'internal',
                'emptyActive':   'Aucun Capteur Interne Actif.',
                'emptyInactive': 'Aucun Capteur Interne Inactif.'
        },
        {
                'title': 'CAPTEURS MODBUS',
                'key': 'modbus',
                'emptyActive':   'Aucun Capteur ModBus Actif.',
                'emptyInactive': 'Aucun Capteur ModBus Inactif.'
        }
        ];

        return [
                ValueListenableBuilder<int?>(
                        valueListenable: maskNotifier,
                        builder: (context, mask, _) {
                                final myMask = mask ?? 0;

                                // 1) Récupère tous les sensors
                                final all = [
                                        ...getSensors(SensorType.internal),
                                        ...getSensors(SensorType.modbus)
                                ];

                                // 2) Regroupe par section
                                final groups = <String, List<SensorsData>>{
                                        'data':     all.where((sensor) => sensor.dataProcessor?.toLowerCase() == 'true').toList(),
                                        'internal': all.where((sensor) => sensor.bus?.toLowerCase() == 'i2c').toList(),
                                        'modbus':   all.where((sensor) => sensor.bus?.toLowerCase() == 'modbus').toList()
                                };

                                // 3) Filtre selon actif/inactif ou configMode
                                List<SensorsData> filter(List<SensorsData> list) {
                                        return list.where(
                                                (sensor) {
                                                        if (configMode) return true;
                                                        final isActive = sensor.maskValue == null || (myMask & sensor.maskValue!) != 0;
                                                        return showInactive ? !isActive : isActive;
                                                }
                                        ).toList();
                                }

                                // 4) Génère un SensorsGroup par section, en choisissant le message “vide”
                                return Column(
                                        children: sections.map((sec) {
                                                        final raw = groups[sec['key']]!;
                                                        final filtered = filter(raw);
                                                        // Choix du message vide selon showInactive
                                                        final emptyMsg = showInactive
                                                                ? sec['emptyInactive'] as String
                                                                : sec['emptyActive']   as String;

                                                        return SensorsGroup(
                                                                title: sec['title'] as String,
                                                                emptyMessage: emptyMsg,
                                                                sensors: filtered,
                                                                itemBuilder: (ctx, sensor) {
                                                                        if (configMode) {
                                                                                // Configuration mode: Affiche le Switch
                                                                                final bit = sensor.maskValue!;
                                                                                final on = (localMask!.value & bit) != 0;
                                                                                return SensorCard(
                                                                                        sensor: sensor,
                                                                                        configMode: true,
                                                                                        isOn: on,
                                                                                        onToggle: (v) {
                                                                                                localMask.value = v
                                                                                                        ? (localMask.value | bit)
                                                                                                        : (localMask.value & ~bit);
                                                                                        }
                                                                                );
                                                                        }
                                                                        else {
                                                                                // Mode normal: tap → popup sauf SD Card + No Switch
                                                                                return SensorCard(
                                                                                        sensor: sensor,
                                                                                        onTap: (sensor.data.isNotEmpty && sensor.title != 'SD Card')
                                                                                                ? () => onTap(ctx, sensor)
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
