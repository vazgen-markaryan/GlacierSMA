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
        final String motDePasse = '';
        late int initialMask;
        late final ValueNotifier<int> localMaskNotifier;
        bool isProcessing = false;

        @override
        void initState() {
                super.initState();
                initialMask = widget.activeMaskNotifier.value ?? 0;
                localMaskNotifier = ValueNotifier<int>(initialMask);
                WidgetsBinding.instance.addPostFrameCallback((_) => _requestPassword());
        }

        @override
        void dispose() {
                localMaskNotifier.dispose();
                super.dispose();
        }

        Future<void> _requestPassword() async {
                final controller = TextEditingController();
                String? errorText;
                while (!authenticated) {
                        final result = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) {
                                        return StatefulBuilder(
                                                builder: (ctx, setState) {
                                                        return AnimatedPadding(
                                                                padding: EdgeInsets.symmetric(horizontal: errorText == null ? 0 : 8),
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
                                errorText = 'Mot de passe incorrect';
                                controller.clear();
                        }
                }
        }

        Future<bool> _onWillPop() async {
                if (localMaskNotifier.value != initialMask) {
                        final leave = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => CustomPopup(
                                        title: 'Quitter sans enregistrer ?',
                                        content: const Text('Vous avez des modifications non enregistrées. Quitter quand même ?'),
                                        actions: [
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Non')),
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Oui'))
                                        ]
                                )
                        );
                        return leave == true;
                }
                return true;
        }

        @override
        Widget build(BuildContext context) {
                if (!authenticated) return const SizedBox.shrink();

                return Stack(
                        children: [
                                // Reconstruit tout le contenu quand localMaskNotifier.value change
                                ValueListenableBuilder<int>(
                                        valueListenable: localMaskNotifier,
                                        builder: (ctx, m, _) {
                                                final hasChanged = m != initialMask;

                                                // Prépare la liste des capteurs
                                                final cfgSensors = allSensors
                                                        .where((s) => s.bitIndex != null)
                                                        .toList()
                                                ..sort((a, b) => a.bitIndex!.compareTo(b.bitIndex!));
                                                final internals = cfgSensors
                                                        .where((s) => s.bus?.toLowerCase() == 'i2c')
                                                        .toList();
                                                final modbus = cfgSensors
                                                        .where((s) => s.bus?.toLowerCase() == 'modbus')
                                                        .toList();

                                                return WillPopScope(
                                                        onWillPop: _onWillPop,
                                                        child: SingleChildScrollView(
                                                                padding: const EdgeInsets.all(defaultPadding),
                                                                child: Column(
                                                                        children: [
                                                                                // --- Internals ---
                                                                                SensorsGroup(
                                                                                        title: 'CAPTEURS INTERNES',
                                                                                        sensors: internals,
                                                                                        emptyMessage: 'Aucun capteur interne à configurer.',
                                                                                        itemBuilder: (ctx, s) {
                                                                                                final bit = s.bitIndex!;
                                                                                                final on = (m & (1 << bit)) != 0;
                                                                                                return SensorCard(
                                                                                                        sensor: s,
                                                                                                        configMode: true,
                                                                                                        isOn: on,
                                                                                                        onToggle: (v) {
                                                                                                                localMaskNotifier.value = v
                                                                                                                        ? (m | (1 << bit))
                                                                                                                        : (m & ~(1 << bit));
                                                                                                        }
                                                                                                );
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: defaultPadding * 2),

                                                                                // --- ModBus ---
                                                                                SensorsGroup(
                                                                                        title: 'CAPTEURS MODBUS',
                                                                                        sensors: modbus,
                                                                                        emptyMessage: 'Aucun capteur ModBus à configurer.',
                                                                                        itemBuilder: (ctx, s) {
                                                                                                final bit = s.bitIndex!;
                                                                                                final on = (m & (1 << bit)) != 0;
                                                                                                return SensorCard(
                                                                                                        sensor: s,
                                                                                                        configMode: true,
                                                                                                        isOn: on,
                                                                                                        onToggle: (v) {
                                                                                                                localMaskNotifier.value = v
                                                                                                                        ? (m | (1 << bit))
                                                                                                                        : (m & ~(1 << bit));
                                                                                                        }
                                                                                                );
                                                                                        }
                                                                                ),

                                                                                const SizedBox(height: defaultPadding * 2),

                                                                                // --- Bouton Appliquer ---
                                                                                Opacity(
                                                                                        opacity: hasChanged ? 1 : 0.5,
                                                                                        child: AbsorbPointer(
                                                                                                absorbing: !hasChanged,
                                                                                                child: ConfigButton(
                                                                                                        idleLabel: 'Appliquer la configuration',
                                                                                                        successLabel: 'Enregistré',
                                                                                                        failureLabel: 'Échec',
                                                                                                        onSubmit: () async {
                                                                                                                // 1) Confirmation BIOS‐style…
                                                                                                                final diffWidgets = <Widget>[];
                                                                                                                for (final s in cfgSensors) {
                                                                                                                        final bit = s.bitIndex!;
                                                                                                                        final oldOn = (initialMask & (1 << bit)) != 0;
                                                                                                                        final newOn = (m & (1 << bit)) != 0;
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
                                                                                                                                                        style: TextStyle(
                                                                                                                                                                color: Colors.white70,
                                                                                                                                                                fontSize: 16
                                                                                                                                                        )
                                                                                                                                                ),
                                                                                                                                                const SizedBox(height: 12),
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

                                                                                                                if (confirm != true) {
                                                                                                                        throw CancelledException();
                                                                                                                }

                                                                                                                // 2) Démarre l’overlay
                                                                                                                setState(() => isProcessing = true);

                                                                                                                // 3) Envoi de la config
                                                                                                                final ok = await widget.messageService.sendSensorConfig(
                                                                                                                        List<bool>.generate(
                                                                                                                                16,
                                                                                                                                (i) => (m & (1 << i)) != 0
                                                                                                                        )
                                                                                                                );

                                                                                                                if (ok) {
                                                                                                                        widget.activeMaskNotifier.value = m;
                                                                                                                        setState(() => initialMask = m);
                                                                                                                }

                                                                                                                // 4) Stop l’overlay
                                                                                                                setState(() => isProcessing = false);

                                                                                                                return ok;
                                                                                                        }
                                                                                                )
                                                                                        )
                                                                                )
                                                                        ]
                                                                )
                                                        )
                                                );
                                        }
                                ),

                                // --- Overlay de chargement bloquant ---
                                if (isProcessing)
                                Positioned.fill(
                                        child: AbsorbPointer(
                                                absorbing: true,
                                                child: Container(
                                                        color: Colors.black45,
                                                        child: const Center(
                                                                child: CircularProgressIndicator()
                                                        )
                                                )
                                        )
                                )
                        ]
                );
        }

        /// Affiche le dialogue “quitter sans sauvegarder ?”
        /// Renvoie `true` si on peut quitter, `false` si on reste.
        Future<bool> confirmDiscard() async {
                if (localMaskNotifier.value == initialMask) return true;
                final leave = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CustomPopup(
                                title: 'Modifications non sauvegardées',
                                content: const Text('Vous avez des changements non appliqués. Quitter quand même ?'),
                                actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non')),
                                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Oui'))
                                ]
                        )
                );
                return leave == true;
        }
}