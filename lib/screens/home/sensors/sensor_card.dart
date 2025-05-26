import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/chip_utils.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_graph_popup.dart';

/// Carte de capteur, avec popup graphique en mode normal.
class SensorCard extends StatelessWidget {
        final SensorsData sensor;
        final bool configMode;
        final bool? isOn;
        final ValueChanged<bool>? onToggle;
        final VoidCallback? onTap;

        const SensorCard({
                Key? key,
                required this.sensor,
                this.configMode = false,
                this.isOn,
                this.onToggle,
                this.onTap
        }) : assert(!configMode || (isOn != null && onToggle != null)), super(key: key);

        @override
        Widget build(BuildContext context) {
                final (iconColor, borderColor, statusLabel) = getStatusUI(sensor.powerStatus);
                String assetPath = sensor.svgIcon!;
                Color svgTint = configMode
                        ? (isOn! ? Colors.green : Colors.red)
                        : iconColor;

                // Cas particulier : override pour le statut Iridium
                if (sensor.header?.toLowerCase() == 'iridium_status') {
                        final entry = sensor.data.entries.firstWhere(
                                (e) => e.key.header.toLowerCase() == 'iridium_signal_quality',
                                orElse: () => MapEntry(
                                        DataMap(name: '', header: '', svgLogo: sensor.svgIcon!),
                                        '0'
                                )
                        );
                        final quality = int.tryParse(entry.value.toString()) ?? -1;
                        final cfg = getIridiumSvgLogoAndColor(quality);
                        assetPath = cfg['icon'] as String;
                        svgTint = cfg['color'] as Color;
                }

                // Génère une ligne de "chips" (code, bus, emplacement)
                Widget buildChipRow() {
                        final chips = <ChipData>[];
                        if (sensor.codeName != null) chips.add(ChipData(sensor.codeName!, Colors.blueGrey.shade700));
                        if (sensor.bus != null) chips.add(ChipData(sensor.bus!, Colors.teal.shade700));
                        if (sensor.placement != null) chips.add(ChipData(sensor.placement!, Colors.grey.shade800));
                        return buildChips(chips, fontSize: 10);
                }

                const graphPath = 'assets/icons/graph.svg';

                return SizedBox(
                        width: double.infinity,
                        child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                        InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: !configMode && sensor.title != 'sensor-data.title.sd_card'
                                                        ? onTap
                                                        : null,
                                                child: Container(
                                                        decoration: BoxDecoration(
                                                                color: secondaryColor,
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(
                                                                        color: configMode
                                                                                ? (isOn! ? Colors.green : Colors.red)
                                                                                : borderColor,
                                                                        width: 3
                                                                )
                                                        ),
                                                        padding: const EdgeInsets.all(defaultPadding),
                                                        child: Row(
                                                                children: [
                                                                        // Icône du capteur
                                                                        SvgPicture.asset(
                                                                                assetPath,
                                                                                height: 50, width: 50,
                                                                                colorFilter: ColorFilter.mode(svgTint, BlendMode.srcIn)
                                                                        ),
                                                                        const SizedBox(width: defaultPadding),

                                                                        // Informations principales
                                                                        Expanded(
                                                                                child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                        children: [
                                                                                                // Titre (nom du capteur)
                                                                                                Text(
                                                                                                        tr(sensor.title ?? tr('home.sensors.title_unknown')),
                                                                                                        style: Theme.of(context).textTheme.bodyLarge,
                                                                                                        overflow: TextOverflow.ellipsis
                                                                                                ),
                                                                                                const SizedBox(height: 4),
                                                                                                buildChipRow() // Ligne de chips
                                                                                        ]
                                                                                )
                                                                        ),

                                                                        // Switch en mode config
                                                                        if (configMode) ...[
                                                                                Switch(
                                                                                        value: isOn!,
                                                                                        onChanged: onToggle,
                                                                                        activeColor: Colors.green,
                                                                                        inactiveThumbColor: Colors.red,
                                                                                        inactiveTrackColor: Colors.red.shade200
                                                                                )
                                                                        ]

                                                                        // Bouton graphique en mode normal (ouvre SensorGraphPopup)
                                                                        else if (
                                                                        sensor.data.isNotEmpty &&
                                                                                sensor.header?.toLowerCase() != 'sdcard' &&
                                                                                sensor.header?.toLowerCase() != 'gps_status' &&
                                                                                sensor.header?.toLowerCase() != 'iridium_status'
                                                                        ) ...[
                                                                                Padding(
                                                                                        padding: const EdgeInsets.only(left: defaultPadding),
                                                                                        child: GestureDetector(
                                                                                                onTap: () => showDialog(
                                                                                                        context: context,
                                                                                                        builder: (_) => SensorGraphPopup(sensor: sensor)
                                                                                                ),
                                                                                                child: SvgPicture.asset(
                                                                                                        graphPath,
                                                                                                        height: 40, width: 40,
                                                                                                        colorFilter: ColorFilter.mode(svgTint, BlendMode.srcIn)
                                                                                                )
                                                                                        )
                                                                                )
                                                                        ]
                                                                ]
                                                        )
                                                )
                                        ),

                                        // Badge de statut en haut à droite
                                        Positioned(
                                                top: -10, right: -10,
                                                child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                                color: configMode ? (isOn! ? Colors.green : Colors.red) : iconColor,
                                                                borderRadius: const BorderRadius.only(
                                                                        bottomLeft: Radius.circular(10),
                                                                        topRight: Radius.circular(10)
                                                                )
                                                        ),
                                                        child: Text(
                                                                configMode
                                                                        ? (isOn! ? tr('home.sensors.status.activated') : tr('home.sensors.status.deactivated'))
                                                                        : statusLabel,
                                                                style: TextStyle(
                                                                        color: configMode
                                                                                ? (isOn! ? Colors.black : Colors.white)
                                                                                : Colors.white,
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.bold
                                                                )
                                                        )
                                                )
                                        )
                                ]
                        )
                );
        }

        /// Retourne (couleurIcône, couleurBordure, libelléStatut) selon powerStatus
        (Color, Color, String) getStatusUI(int? status) {
                switch (status) {
                        case 1:  return (Colors.green,  Colors.green,  tr('home.sensors.status.operational'));
                        case 2:  return (Colors.yellow, Colors.yellow, tr('home.sensors.status.disconnected'));
                        case 3:  return (Colors.red,    Colors.red,    tr('home.sensors.status.error'));
                        case 0:  return (Colors.grey,   Colors.grey,   tr('home.sensors.status.unknown'));
                        default: return (Colors.black,  Colors.black,  tr('home.sensors.status.disabled'));
                }
        }
}