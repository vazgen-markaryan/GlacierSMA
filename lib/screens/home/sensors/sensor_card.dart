import 'sensors_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

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
        }) : assert(!configMode || (isOn != null && onToggle != null)),
                super(key: key);

        @override
        Widget build(BuildContext context) {
                final (iconColor, borderColor, statusLabel) = getStatusUI(sensor.powerStatus);

                Widget buildChips() {
                        return Wrap(
                                spacing: 4, runSpacing: 2,
                                children: [
                                        if (sensor.code != null) buildChip(sensor.code!, Colors.blueGrey.shade700),
                                        if (sensor.bus != null) buildChip(sensor.bus!, Colors.teal.shade700),
                                        if (sensor.place != null) buildChip(sensor.place!, Colors.grey.shade800)
                                ]
                        );
                }

                final card = Container(
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
                                        SvgPicture.asset(
                                                sensor.svgIcon!,
                                                height: 50, width: 50,
                                                colorFilter: ColorFilter.mode(
                                                        configMode
                                                                ? (isOn! ? Colors.green : Colors.red)
                                                                : iconColor,
                                                        BlendMode.srcIn
                                                )
                                        ),
                                        const SizedBox(width: defaultPadding),
                                        Expanded(
                                                child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                                Text(
                                                                        sensor.title ?? 'Capteur Inconnu',
                                                                        style: Theme.of(context).textTheme.bodyLarge,
                                                                        overflow: TextOverflow.ellipsis
                                                                ),
                                                                const SizedBox(height: 4),
                                                                buildChips()
                                                        ]
                                                )
                                        ),
                                        if (configMode)
                                        Switch(
                                                value: isOn!,
                                                onChanged: onToggle,
                                                activeColor: Colors.green,
                                                inactiveThumbColor: Colors.red,
                                                inactiveTrackColor: Colors.red.shade200
                                        )
                                ]
                        )
                );

                return SizedBox(
                        width: double.infinity,
                        child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                        if (!configMode)
                                        InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: (sensor.data.isNotEmpty && sensor.title != 'SD Card')
                                                        ? onTap
                                                        : null,
                                                child: card
                                        )
                                        else
                                        card,
                                        Positioned(
                                                top: -10, right: -10,
                                                child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                                color: configMode
                                                                        ? (isOn! ? Colors.green : Colors.red)
                                                                        : iconColor,
                                                                borderRadius: const BorderRadius.only(
                                                                        bottomLeft: Radius.circular(10),
                                                                        topRight: Radius.circular(10)
                                                                )
                                                        ),
                                                        child: Text(
                                                                configMode
                                                                        ? (isOn! ? 'Activé' : 'Désactivé')
                                                                        : statusLabel,
                                                                style: TextStyle(
                                                                        color: configMode
                                                                                ? (isOn! ? Colors.black : Colors.white)
                                                                                : (sensor.powerStatus == null || sensor.powerStatus == 0)
                                                                                        ? Colors.white
                                                                                        : Colors.black,
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

        Widget buildChip(String text, Color bg) => Chip(
                label: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: bg,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap
        );

        (Color, Color, String) getStatusUI(int? status) {
                switch (status) {
                        case 1: return (Colors.green,  Colors.green,  'Fonctionne');
                        case 2: return (Colors.yellow, Colors.yellow, 'Déconnecté');
                        case 3: return (Colors.red,    Colors.red,    'Erreur');
                        case 0: return (Colors.grey,   Colors.grey,   'Inconnu');
                        default:return (Colors.black,  Colors.black,  'Désactivé');
                }
        }
}