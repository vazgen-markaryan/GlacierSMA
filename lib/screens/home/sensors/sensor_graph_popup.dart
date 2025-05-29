import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

class SensorGraphPopup extends StatefulWidget {
        final SensorsData sensor;
        const SensorGraphPopup({Key? key, required this.sensor}) : super(key: key);

        @override
        SensorGraphPopupState createState() => SensorGraphPopupState();
}

class SensorGraphPopupState extends State<SensorGraphPopup> {
        static const double windowX = 60.0;

        @override
        void initState() {
                super.initState();
                widget.sensor.dataNotifier.addListener(onData);
        }

        @override
        void dispose() {
                widget.sensor.dataNotifier.removeListener(onData);
                super.dispose();
        }

        void onData() => setState(() {
                }
        );

        /// Formatte un label (1000→1k, 1500→1.5k, etc.)
        String formatLabel(double value) {
                if (value.abs() >= 1000) {
                        final k = value / 1000;
                        final s = (k % 1 == 0) ? k.toInt().toString() : k.toStringAsFixed(1);
                        return '${s}k';
                }
                return value.toInt().toString();
        }

        @override
        Widget build(BuildContext context) {
                return CustomPopup(
                        // Titre du popup
                        title: tr(widget.sensor.title ?? ''),
                        content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                        for (final entry in widget.sensor.history.entries) 
                                                ...[

                                                        // Titre du champ + unité, centré sur le chart
                                                        Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                                child: Text(
                                                                        '${tr(entry.key.name)} (${getUnitForHeader(entry.key.header).trim()})',
                                                                        textAlign: TextAlign.center,
                                                                        style: Theme.of(context).textTheme.titleMedium
                                                                )
                                                        ),

                                                        // Le graphique
                                                        Builder(
                                                                builder: (_) {

                                                                        // On filtre les FlSpot des dernières 60s
                                                                        final rawSpots = entry.value;
                                                                        final lastX = rawSpots.isNotEmpty ? rawSpots.last.x : 0.0;
                                                                        final spots = rawSpots
                                                                                .where((pt) => pt.x >= lastX - windowX)
                                                                                .map((pt) => FlSpot(pt.x - (lastX - windowX), pt.y))
                                                                                .toList();

                                                                        // Calcule min/max
                                                                        final maxData = spots.isNotEmpty ? spots.map((e) => e.y).reduce(max) : 0.0;
                                                                        final minData = spots.isNotEmpty ? spots.map((e) => e.y).reduce(min) : 0.0;

                                                                        // Si c'est Luxmètre, on met une marge de 1000 sinon 10
                                                                        final margin = entry.key.header
                                                                                .toLowerCase()
                                                                                .contains('mb_asl20')
                                                                                ? 1000.0 : 10.0;

                                                                        // On calcule les limites Y du graphique
                                                                        double minY, maxY;

                                                                        if (minData >= 0) {
                                                                                minY = 0;
                                                                                maxY = maxData + margin;
                                                                        }
                                                                        else if (maxData <= 0) {
                                                                                minY = minData - margin;
                                                                                maxY = 0;
                                                                        }
                                                                        else {
                                                                                minY = minData - margin;
                                                                                maxY = maxData + margin;
                                                                        }

                                                                        // Réserve assez d'espace pour labels Y
                                                                        final topLabel = formatLabel(maxY);
                                                                        final bottomLabel = formatLabel(minY);
                                                                        const double fontSize = 12;
                                                                        final int maxChars = max(topLabel.length, bottomLabel.length);
                                                                        final double reservedSize = maxChars * (fontSize * 0.6) + 8;

                                                                        // On affiche le graphique
                                                                        return Padding(
                                                                                padding: const EdgeInsets.only(right: 16.0),
                                                                                child: AspectRatio(
                                                                                        aspectRatio: 16 / 9,
                                                                                        child: LineChart(
                                                                                                LineChartData(
                                                                                                        minX: 0,
                                                                                                        maxX: windowX,
                                                                                                        minY: minY,
                                                                                                        maxY: maxY,
                                                                                                        gridData: FlGridData(show: true), // Quadrillage true
                                                                                                        borderData: FlBorderData(show: true), // Bordure true

                                                                                                        lineBarsData: [
                                                                                                                LineChartBarData(
                                                                                                                        spots: spots,
                                                                                                                        isCurved: true,
                                                                                                                        isStrokeCapRound: true,
                                                                                                                        barWidth: 2,
                                                                                                                        dotData: const FlDotData(show: false),
                                                                                                                        belowBarData: BarAreaData(show: true)
                                                                                                                )
                                                                                                        ],

                                                                                                        titlesData: FlTitlesData(
                                                                                                                // On cache axes haut/bas/droite
                                                                                                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                                                                                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                                                                                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                                                                                                                // On n'affiche que minY et maxY à gauche
                                                                                                                leftTitles: AxisTitles(
                                                                                                                        sideTitles: SideTitles(
                                                                                                                                showTitles: true,
                                                                                                                                reservedSize: reservedSize,
                                                                                                                                getTitlesWidget: (value, meta) {
                                                                                                                                        if (value == minY || value == maxY) {
                                                                                                                                                return Text(
                                                                                                                                                        formatLabel(value),
                                                                                                                                                        style: const TextStyle(
                                                                                                                                                                color: Colors.white70,
                                                                                                                                                                fontSize: fontSize
                                                                                                                                                        )
                                                                                                                                                );
                                                                                                                                        }
                                                                                                                                        return const SizedBox.shrink();
                                                                                                                                }
                                                                                                                        )
                                                                                                                )
                                                                                                        )
                                                                                                )
                                                                                        )
                                                                                )
                                                                        );
                                                                }
                                                        ),

                                                        // Label bas "Temps réel"
                                                        Padding(
                                                                padding: const EdgeInsets.only(top: 6, bottom: 12),
                                                                child: Text(
                                                                        tr('graph.real_time'),
                                                                        textAlign: TextAlign.center,
                                                                        style: const TextStyle(color: Colors.white70, fontSize: 12)
                                                                )
                                                        )
                                                ]
                                ]
                        ),
                        actions: []
                );
        }
}