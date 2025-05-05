import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rev_glacier_sma_mobile/utils/chip_utils.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/config/config_button.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensor_card.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_group.dart';

class DiffRow extends StatelessWidget {
        final String svgIcon;
        final String title;
        final String? bus;
        final String? code;
        final String? place;
        final bool oldOn;
        final bool newOn;

        const DiffRow({
                Key? key,
                required this.svgIcon,
                required this.title,
                this.bus,
                this.code,
                this.place,
                required this.oldOn,
                required this.newOn
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                // couleur du chip pour le bus
                final Color busColor;
                switch (bus?.toLowerCase()) {
                        case 'modbus':
                                busColor = Colors.teal.shade700;
                                break;
                        case 'i2c':
                                busColor = Colors.blueGrey.shade700;
                                break;
                        default:
                        busColor = Colors.grey.shade800;
                }

                // préparation de la liste de chips
                final chips = <ChipData>[];
                if (bus != null) chips.add(ChipData(bus!, busColor));
                if (code != null) chips.add(ChipData(code!, Colors.blueGrey.shade700));
                if (place != null) chips.add(ChipData(place!, Colors.grey.shade800));

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
                                        // Icône + titre + chips en dessous
                                        Row(
                                                children: [
                                                        SvgPicture.asset(
                                                                svgIcon,
                                                                height: 24,
                                                                width: 24,
                                                                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        // titre sans troncature
                                                                        Text(
                                                                                title,
                                                                                style: const TextStyle(color: Colors.white70, fontSize: 12)
                                                                        ),
                                                                        const SizedBox(height: 4),
                                                                        // 3 chips : bus, code, place
                                                                        buildChips(chips, fontSize: 10, spacing: 4, runSpacing: 2)
                                                                ]
                                                        )
                                                ]
                                        ),

                                        // OLD → NEW sous forme d’icônes
                                        Row(
                                                children: [
                                                        Icon(
                                                                oldOn ? Icons.check_circle : Icons.cancel,
                                                                color: oldOn ? Colors.green : Colors.red,
                                                                size: 16
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Text('→', style: TextStyle(color: Colors.white)),
                                                        const SizedBox(width: 4),
                                                        Icon(
                                                                newOn ? Icons.check_circle : Icons.cancel,
                                                                color: newOn ? Colors.green : Colors.red,
                                                                size: 16
                                                        )
                                                ]
                                        )
                                ]
                        )
                );
        }
}

/// Écran “Configuration des capteurs”
/// Utilise une copie **locale** du mask pour ne charger la config initiale qu'une seule fois
/// Ne met à jour le mask global **qu’après** l’envoi.
class ConfigScreen extends StatefulWidget {
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;
        final VoidCallback onCancel;

        const ConfigScreen({
                Key? key,
                required this.activeMaskNotifier,
                required this.messageService,
                required this.onCancel
        }) : super(key: key);

        @override
        ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
        bool authenticated = false;
        final String motDePasse = 'LME2025';
        late final int initialMask;
        late final ValueNotifier<int> localMaskNotifier;

        @override
        void initState() {
                super.initState();
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier<int>(initialMask);
                WidgetsBinding.instance.addPostFrameCallback((_) => _requestPassword());
        }

        Future<void> _requestPassword() async {
                final controller = TextEditingController();
                String? errorText;

                while (!authenticated) {
                        final result = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) {
                                        return StatefulBuilder(builder: (ctx, setState) {
                                                        return AnimatedPadding(
                                                                // simple “shake” visuel : on bouge horizontalement sur erreur
                                                                padding: EdgeInsets.symmetric(
                                                                        horizontal: errorText == null ? 0 : 8
                                                                ),
                                                                duration: const Duration(milliseconds: 50),
                                                                child: CustomPopup(
                                                                        title: 'Mot de passe requis',
                                                                        content: Column(
                                                                                children: [
                                                                                        TextField(
                                                                                                controller: controller,
                                                                                                obscureText: true,
                                                                                                decoration: InputDecoration(
                                                                                                        labelText: 'Mot de passe',
                                                                                                        errorText: errorText
                                                                                                )
                                                                                        )
                                                                                ]
                                                                        ),
                                                                        actions: [
                                                                                TextButton(
                                                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                                                        child: const Text('Quitter')
                                                                                ),
                                                                                TextButton(
                                                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                                                        child: const Text('Valider')
                                                                                )
                                                                        ]
                                                                )
                                                        );
                                                }
                                        );
                                }
                        );

                        if (result != true) {
                                widget.onCancel();
                                return;
                        }
                        if (controller.text == motDePasse) {
                                setState(() => authenticated = true);
                        }
                        else {
                                // on vide et on affiche l’erreur inline (et la padding fera un mini shake)
                                errorText = 'Mot de passe incorrect';
                                controller.clear();
                        }
                }
        }

        @override
        Widget build(BuildContext context) {
                if (!authenticated) return const SizedBox.shrink();

                return WillPopScope(
                        onWillPop: () async {
                                if (localMaskNotifier.value != initialMask) {
                                        final leave = await showDialog<bool>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (ctx) => CustomPopup(
                                                        title: 'Quitter sans enregistrer ?',
                                                        content: const Text('Vous avez des modifications non enregistrées. Quitter quand même ?'),
                                                        actions: [
                                                                TextButton(
                                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                                        child: const Text('Non')
                                                                ),
                                                                TextButton(
                                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                                        child: const Text('Oui')
                                                                )
                                                        ]
                                                )
                                        );
                                        return leave == true;
                                }
                                return true;
                        },
                        child: ValueListenableBuilder<int>(
                                valueListenable: localMaskNotifier,
                                builder: (ctx, m, _) {
                                        final cfgSensors = allSensors
                                                .where((s) => s.bitIndex != null)
                                                .toList()
                                        ..sort((a, b) => a.bitIndex!.compareTo(b.bitIndex!));

                                        final internals = cfgSensors.where((s) => s.bus?.toLowerCase() == 'i2c').toList();
                                        final modbus = cfgSensors.where((s) => s.bus?.toLowerCase() == 'modbus').toList();

                                        final hasChanged = m != initialMask;

                                        return SingleChildScrollView(
                                                padding: const EdgeInsets.all(defaultPadding),
                                                child: Column(
                                                        children: [
                                                                SensorsGroup(
                                                                        title: 'CAPTEURS INTERNES',
                                                                        sensors: internals,
                                                                        emptyMessage: 'Aucun capteur interne à configurer.',
                                                                        itemBuilder: (ctx, s) {
                                                                                final bit = s.bitIndex!;
                                                                                return SensorCard(
                                                                                        sensor: s,
                                                                                        configMode: true,
                                                                                        isOn: (m & (1 << bit)) != 0,
                                                                                        onToggle: (v) {
                                                                                                final newMask = v ? (m | (1 << bit)) : (m & ~(1 << bit));
                                                                                                localMaskNotifier.value = newMask;
                                                                                        }
                                                                                );
                                                                        }
                                                                ),
                                                                const SizedBox(height: defaultPadding * 2),
                                                                SensorsGroup(
                                                                        title: 'CAPTEURS MODBUS',
                                                                        sensors: modbus,
                                                                        emptyMessage: 'Aucun capteur ModBus à configurer.',
                                                                        itemBuilder: (ctx, s) {
                                                                                final bit = s.bitIndex!;
                                                                                return SensorCard(
                                                                                        sensor: s,
                                                                                        configMode: true,
                                                                                        isOn: (m & (1 << bit)) != 0,
                                                                                        onToggle: (v) {
                                                                                                final newMask = v ? (m | (1 << bit)) : (m & ~(1 << bit));
                                                                                                localMaskNotifier.value = newMask;
                                                                                        }
                                                                                );
                                                                        }
                                                                ),
                                                                const SizedBox(height: defaultPadding * 2),

                                                                Opacity(
                                                                        opacity: hasChanged ? 1 : 0.5,
                                                                        child: AbsorbPointer(
                                                                                absorbing: !hasChanged,
                                                                                child: Padding(
                                                                                        padding:
                                                                                        const EdgeInsets.symmetric(horizontal: defaultPadding),
                                                                                        child: ConfigButton(
                                                                                                idleLabel: 'Appliquer la configuration',
                                                                                                successLabel: 'Enregistré',
                                                                                                failureLabel: 'Erreur',
                                                                                                onSubmit: () async {
                                                                                                        // 1) Calcul des diffs avec objets complets
                                                                                                        final diffWidgets = <Widget>[];
                                                                                                        for (final s in allSensors.where((s) => s.bitIndex != null)) {
                                                                                                                final bit = s.bitIndex!;
                                                                                                                final oldOn = (initialMask & (1 << bit)) != 0;
                                                                                                                final newOn = (localMaskNotifier.value & (1 << bit)) != 0;
                                                                                                                if (oldOn != newOn) {
                                                                                                                        diffWidgets.add(DiffRow(
                                                                                                                                        svgIcon: s.svgIcon!,
                                                                                                                                        title: s.title!,
                                                                                                                                        bus: s.bus,
                                                                                                                                        code: s.code,
                                                                                                                                        place: s.place,
                                                                                                                                        oldOn: oldOn,
                                                                                                                                        newOn: newOn
                                                                                                                                ));
                                                                                                                }

                                                                                                        }

                                                                                                        // 2) Popup de confirmation BIOS-style
                                                                                                        // Après avoir collecté diffWidgets (avec DiffRow au lieu d’un String)
                                                                                                        final confirm = await showDialog<bool>(
                                                                                                                context: context,
                                                                                                                barrierDismissible: false,
                                                                                                                builder: (ctx) => CustomPopup(
                                                                                                                        title: 'Confirmer l’application',
                                                                                                                        content: Column(
                                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                                children: [
                                                                                                                                        const Text(
                                                                                                                                                'Les capteurs modifiés :',
                                                                                                                                                style: TextStyle(color: Colors.white70, fontSize: 16)
                                                                                                                                        ),
                                                                                                                                        const SizedBox(height: 12),
                                                                                                                                        // Ici on affiche chaque DiffRow
                                                                                                                                        ...diffWidgets
                                                                                                                                ]
                                                                                                                        ),
                                                                                                                        actions: [
                                                                                                                                TextButton(
                                                                                                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                                                                                                        child: const Text('Annuler')
                                                                                                                                ),
                                                                                                                                TextButton(
                                                                                                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                                                                                                        child: const Text('Valider')
                                                                                                                                )
                                                                                                                        ]
                                                                                                                )
                                                                                                        );

                                                                                                        if (confirm != true) return false;

                                                                                                        // 3) Popup de progression et envoi
                                                                                                        showDialog(
                                                                                                                context: context,
                                                                                                                barrierDismissible: false,
                                                                                                                builder: (_) => const CustomPopup(
                                                                                                                        title: 'Application en cours',
                                                                                                                        content: Padding(
                                                                                                                                padding: EdgeInsets.symmetric(vertical: 20),
                                                                                                                                child: CircularProgressIndicator()
                                                                                                                        ),
                                                                                                                        actions: []
                                                                                                                )
                                                                                                        );

                                                                                                        final ok = await widget.messageService.sendSensorConfig(
                                                                                                                List<bool>.generate(
                                                                                                                        16,
                                                                                                                        (i) => (localMaskNotifier.value & (1 << i)) != 0
                                                                                                                )
                                                                                                        );
                                                                                                        if (ok) {
                                                                                                                widget.activeMaskNotifier.value = localMaskNotifier.value;
                                                                                                        }

                                                                                                        Navigator.of(context, rootNavigator: true).pop();
                                                                                                        return ok;
                                                                                                }
                                                                                        )
                                                                                )
                                                                        )
                                                                )
                                                        ]
                                                )
                                        );
                                }
                        )
                );
        }
}