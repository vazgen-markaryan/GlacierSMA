/// Écran de debug : affiche le flux de logs STATUS/VALEURS et liste les capteurs inactifs.

import 'package:flutter/material.dart';
import 'components/debug_log_updater.dart';
import 'components/debug_log_processor.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';

class DebugScreen extends StatelessWidget {
        /// Manager responsable de la collecte et de la publication des logs debug
        final DebugLogUpdater debugLogManager;

        const DebugScreen({Key? key, required this.debugLogManager}) : super(key: key);

        @override
        Widget build(BuildContext context) {
                // Récupère tous les capteurs de toutes les catégories
                final allSensors = [
                        ...getSensors(SensorType.internal),
                        ...getSensors(SensorType.modbus),
                        ...getSensors(SensorType.stevenson),
                        ...getSensors(SensorType.stevensonStatus)
                ];

                // Filtre pour ne garder que ceux dont powerStatus est null (inactifs)
                final inactiveSensors = allSensors.where((s) => s.powerStatus == null).toList();

                return Scaffold(
                        backgroundColor: backgroundColor,
                        body: SingleChildScrollView(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                // 1) Affiche le tableau de logs debug (STATUS et VALEURS)
                                                DebugLogProcessor(debugLogManager: debugLogManager),

                                                // 2) Espacement entre la section logs et la liste des capteurs
                                                const SizedBox(height: defaultPadding * 2),

                                                // 3) Affiche un groupe de cartes pour les capteurs inactifs seulement si ils existent
                                                if (inactiveSensors.isNotEmpty)
                                                SensorsGroup(
                                                        title: 'Capteurs inactifs',
                                                        sensors: inactiveSensors
                                                )
                                        ]
                                )
                        )
                );
        }
}