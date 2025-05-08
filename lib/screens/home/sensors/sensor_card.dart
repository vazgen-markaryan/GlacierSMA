import 'sensors_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rev_glacier_sma_mobile/utils/chip_utils.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/switch_utils.dart';

/// Widget représentant une carte de capteur, avec deux modes :
///  • mode affichage normal (configMode = false)  
///  • mode configuration (configMode = true) où l’on peut activer/désactiver
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
                // Couleur de l’icône, couleur de bordure et libellé du statut (non-config mode)
                final (iconColor, borderColor, statusLabel) = getStatusUI(sensor.powerStatus);

                // Détermination du chemin et de la teinte du SVG
                String assetPath = sensor.svgIcon!;
                Color svgTint = configMode
                        ? (isOn! ? Colors.green : Colors.red)
                        : iconColor;

                // Si c’est le capteur Iridium, override le SVG en fonction de la qualité brute
                if (sensor.header?.toLowerCase() == 'iridium_status') {
                        final entry = sensor.data.entries.firstWhere(
                                (e) => e.key.header.toLowerCase() == 'iridium_signal_quality',
                                orElse: () => MapEntry(
                                        DataMap(name: '', header: '', svgLogo: sensor.svgIcon!),
                                        '0'
                                )
                        );
                        final quality = int.tryParse(entry.value.toString()) ?? 0;
                        final config = getIridiumSvgLogoAndColor(quality);
                        assetPath = config['icon']  as String;
                        svgTint = config['color'] as Color;
                }

                // Construction de la ligne de “chips” (code, bus, place)
                Widget buildChipRow() {
                        final chips = <ChipData>[];
                        if (sensor.code != null) chips.add(ChipData(sensor.code!, Colors.blueGrey.shade700));
                        if (sensor.bus != null) chips.add(ChipData(sensor.bus!, Colors.teal.shade700));
                        if (sensor.place != null) chips.add(ChipData(sensor.place!, Colors.grey.shade800));
                        return buildChips(chips, fontSize: 10);
                }

                // Contenu principal de la carte
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

                                        // Icône SVG
                                        SvgPicture.asset(
                                                assetPath,
                                                height: 50, width: 50,
                                                colorFilter: ColorFilter.mode(svgTint, BlendMode.srcIn)
                                        ),

                                        const SizedBox(width: defaultPadding),

                                        // Titre + chips
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
                                                                buildChipRow()
                                                        ]
                                                )
                                        ),

                                        // Switch en mode configuration
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

                // Retourne la carte, avec le petit badge de statut en coin
                return SizedBox(
                        width: double.infinity,
                        child: Stack(
                                clipBehavior: Clip.none,
                                children: [

                                        // Zone cliquable en mode normal
                                        if (!configMode)
                                        InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: (sensor.data.isNotEmpty && sensor.title != 'SD Card')
                                                        ? onTap
                                                        : null,
                                                child: card
                                        )
                                        else card,

                                        // Badge positionné en haut-droite
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

        /// Retourne (couleurIcône, couleurBordure, libelléStatut)
        (Color, Color, String) getStatusUI(int? status) {
                switch (status) {
                        case 1:  return (Colors.green,  Colors.green,  'Fonctionne');
                        case 2:  return (Colors.yellow, Colors.yellow, 'Déconnecté');
                        case 3:  return (Colors.red,    Colors.red,    'Erreur');
                        case 0:  return (Colors.grey,   Colors.grey,   'Inconnu');
                        default: return (Colors.black,  Colors.black,  'Désactivé');
                }
        }
}