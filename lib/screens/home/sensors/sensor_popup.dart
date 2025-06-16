import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/global_utilities.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';

/// Affiche le popup de détails des capteurs dans l'application.
/// Génère dynamiquement les lignes de données selon le capteur.
/// Supporte l'affichage spécial pour le GPS (Google Maps).

class SensorPopup extends StatefulWidget {
        final SensorsData sensor;
        const SensorPopup({super.key, required this.sensor});
        @override
        State<SensorPopup> createState() => SensorPopupState();
}

class SensorPopupState extends State<SensorPopup> with SingleTickerProviderStateMixin {
        late final AnimationController controller;
        late final Animation<double> scale;
        late String timestamp;
        Timer? timer;
        String? errorMessage;

        @override
        void initState() {
                super.initState();
                controller = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 250)
                )..forward();
                scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);

                timestamp = now();
                timer = Timer.periodic(
                        const Duration(seconds: 1),
                        (_) => setState(() => timestamp = now())
                );
        }

        String now() => DateFormat("dd-MM-yyyy   HH:mm:ss").format(DateTime.now());

        @override
        void dispose() {
                controller.dispose();
                timer?.cancel();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                final isGpsSensor = widget.sensor.title?.toLowerCase().contains('gps') ?? false;

                return ScaleTransition(
                        scale: scale,
                        child: CustomPopup(
                                title: (tr(widget.sensor.title ?? 'home.sensors.sensor_details')),
                                content: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Scrollbar(
                                                thumbVisibility: true,
                                                radius: const Radius.circular(8),
                                                thickness: 6,
                                                child: Padding(
                                                        padding: const EdgeInsets.only(right: 12),
                                                        child: SingleChildScrollView(
                                                                child: ValueListenableBuilder<Map<DataMap, dynamic>>(
                                                                        valueListenable: widget.sensor.dataNotifier,
                                                                        builder: (_, data, __) {
                                                                                final items = data.entries.toList();

                                                                                final gpsData = GpsUtils.extractGpsValues(data);
                                                                                final latitude = gpsData['latitude'];
                                                                                final longitude = gpsData['longitude'];

                                                                                return Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                                // Horodatage
                                                                                                Text(
                                                                                                        tr('home.sensors.updated_at', namedArgs: {'timestamp': timestamp}),
                                                                                                        style: const TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic)
                                                                                                ),
                                                                                                const SizedBox(height: 12),

                                                                                                ...items.map((event) => buildRow(event.key, event.value)).toList(),

                                                                                                if (isGpsSensor)
                                                                                                buildGpsRow(
                                                                                                        latitude: latitude,
                                                                                                        longitude: longitude
                                                                                                ),

                                                                                                if (errorMessage != null)
                                                                                                Padding(
                                                                                                        padding: const EdgeInsets.only(top: 4),
                                                                                                        child: Align(
                                                                                                                alignment: Alignment.center,
                                                                                                                child: Text(
                                                                                                                        errorMessage!,
                                                                                                                        style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                                                                                                                        textAlign: TextAlign.center
                                                                                                                )
                                                                                                        )
                                                                                                )
                                                                                        ]
                                                                                );
                                                                        }
                                                                )
                                                        )
                                                )
                                        )
                                ),
                                actions: const[]
                        )
                );
        }

        /// Génère les lignes normales (non-GPS)
        Widget buildRow(DataMap key, dynamic value) {
                String display = value.toString();
                if (key.header.toLowerCase() == 'iridium_signal_quality') {
                        final quality = int.tryParse(display) ?? -1;
                        final text = getIridiumSvgLogoAndColor(quality)['value'] as String;
                        display = '$display ($text)';
                }

                return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                        Row(
                                                children: [
                                                        SvgPicture.asset(
                                                                key.svgLogo,
                                                                height: 24,
                                                                width: 24,
                                                                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                                tr(key.name),
                                                                style: const TextStyle(color: Colors.white70, fontSize: 15)
                                                        )
                                                ]
                                        ),
                                        Flexible(
                                                child: Text(
                                                        display,
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                        textAlign: TextAlign.right,
                                                        overflow: TextOverflow.ellipsis
                                                )
                                        )
                                ]
                        )
                );
        }

        /// Génère le row complet Google Maps (entier cliquable)
        Widget buildGpsRow({required double? latitude, required double? longitude}) {
                return GestureDetector(
                        onTap: () {
                                if (latitude != null && longitude != null && latitude != 0 && longitude != 0) {
                                        openInGoogleMaps(
                                                latitude: latitude,
                                                longitude: longitude,
                                                onError: showTemporaryError
                                        );
                                }
                                else {
                                        showTemporaryError(tr("home.sensors.gps_data_unavailable"));
                                }
                        },
                        child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                        color: Colors.blue.shade400,
                                        borderRadius: BorderRadius.circular(12)
                                ),
                                child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                                SvgPicture.asset(
                                                        'assets/icons/map-pin.svg',
                                                        height: 26,
                                                        width: 26,
                                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                        'Google Maps',
                                                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)
                                                )
                                        ]
                                )
                        )
                );
        }

        void showTemporaryError(String message) {
                setState(() {
                                errorMessage = message;
                        }
                );
                Future.delayed(const Duration(seconds: 2),
                        () {
                                if (mounted) {
                                        setState(() {
                                                        errorMessage = null;
                                                }
                                        );
                                }
                        }
                );
        }
}

/// Extraction des données GPS à partir du SensorsData
class GpsUtils {
        static Map<String, double?> extractGpsValues(Map<DataMap, dynamic> data) {
                double? latitude;
                double? longitude;

                for (final entry in data.entries) {
                        final key = entry.key.header.toLowerCase();
                        final value = entry.value;

                        if (key.contains('latitude')) {
                                latitude = (value is num) ? value.toDouble() : double.tryParse(value.toString());
                        }
                        if (key.contains('longitude')) {
                                longitude = (value is num) ? value.toDouble() : double.tryParse(value.toString());
                        }
                }
                return {
                        'latitude': latitude,
                        'longitude': longitude
                };
        }
}

/// Ouvre Google Maps à la position spécifiée.
Future<void> openInGoogleMaps({
        required double latitude,
        required double longitude,
        required void Function(String) onError
}) async {
        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
        try {
                final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                if (!launched) {
                        onError(tr("home.sensors.error_launching_gmap"));
                }
        }
        catch (e) {
                onError(tr("home.sensors.error_launching_gmap") + ': $e');
        }
}