import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/dashboard/components/sensors.dart';

import '../../constants.dart';
import '../../sensors_donnees/sensors_data.dart';
import 'components/header.dart';

class DashboardScreen extends StatelessWidget {
        const DashboardScreen({super.key});

        @override
        Widget build(BuildContext context) {
                return SafeArea(
                        child: SingleChildScrollView(
                                primary: false,
                                padding: EdgeInsets.all(defaultPadding),
                                child: Column(
                                        children: [
                                                Header(),
                                                SizedBox(height: defaultPadding),
                                                Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                                Expanded(
                                                                        flex: 5,
                                                                        child: Column(
                                                                                children: [
                                                                                        MySensors(
                                                                                                title: "Les Capteurs Internes",
                                                                                                sensors: internalSensors
                                                                                        ),
                                                                                        SizedBox(height: defaultPadding),
                                                                                        MySensors(
                                                                                                title: "Les Capteurs du Vent (dummy status)",
                                                                                                sensors: windSensors
                                                                                        ),
                                                                                        SizedBox(height: defaultPadding),
                                                                                        MySensors(
                                                                                                title: "Les Capteurs Stevenson (dummy status)",
                                                                                                sensors: stevensonSensors
                                                                                        ),
                                                                                        SizedBox(height: defaultPadding)
                                                                                ]
                                                                        )
                                                                )
                                                        ]
                                                )
                                        ]
                                )
                        )
                );
        }
}