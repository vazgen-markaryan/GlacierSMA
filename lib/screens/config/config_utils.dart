import 'config_custom_sensor.dart';
import 'package:flutter/material.dart';
import '../home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';

/// Exception levée quand l’utilisateur annule la confirmation
class CancelledException implements Exception {
}

/// Affiche un popup “Mot de passe requis”
/// Boucle tant que le mot de passe est incorrect, ou renvoie false si l’utilisateur quitte
Future<bool> showPasswordDialog(
        BuildContext context, {
                required String motDePasse
        }) async {
        final controller = TextEditingController();
        String? errorText;
        while (true) {
                final result = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
                                        return AnimatedPadding(
                                                padding: EdgeInsets.symmetric(horizontal: errorText == null ? 0 : 8),
                                                duration: const Duration(milliseconds: 50),
                                                child: CustomPopup(
                                                        title: 'Mot de passe requis',
                                                        content: TextField(
                                                                controller: controller,
                                                                obscureText: true,
                                                                decoration: InputDecoration(
                                                                        labelText: 'Mot de passe',
                                                                        errorText: errorText
                                                                )
                                                        ),
                                                        actions: [
                                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Quitter')),
                                                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Valider'))
                                                        ]
                                                )
                                        );
                                }
                        )
                );

                if (result != true) return false;
                if (controller.text == motDePasse) return true;

                // Affiche l’erreur et recommence
                errorText = 'Mot de passe incorrect';
                controller.clear();
        }
}

/// Affiche un popup “Quitter sans enregistrer?”
Future<bool> showDiscardDialog(BuildContext context) async {
        final leave = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => CustomPopup(
                        title: 'Modifications non sauvegardées',
                        content: const Text('Vous avez des changements non appliqués. Quitter quand même ?'),
                        actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Non')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Oui'))
                        ]
                )
        );
        return leave == true;
}

/// Construit la liste des differences, affiche la confirmation BIOS-style,
/// Envoie la config si validé.
/// Lance CancelledException si l’utilisateur annule la confirmation.
Future<bool> submitConfiguration({
        required BuildContext context,
        required int initialMask,
        required int newMask,
        required MessageService messageService
}) async {
        // 1) Construire les lignes de différence
        final differences = <Widget>[];
        for (final s in allSensors.where((s) => s.bitIndex != null)) {
                final bit = s.bitIndex!;
                final oldOn = (initialMask & (1 << bit)) != 0;
                final newOn = (newMask & (1 << bit)) != 0;
                if (oldOn != newOn) {
                        differences.add(
                                ConfigCustomSensor(
                                        svgIcon: s.svgIcon!,
                                        title: s.title!,
                                        bus: s.bus,
                                        code: s.code,
                                        place: s.place,
                                        oldStatus: oldOn,
                                        newStatus: newOn
                                )
                        );
                }
        }

        // 2) Popup de confirmation BIOS-style
        final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CustomPopup(
                        title: 'Confirmer l’application',
                        content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        const Text('Les capteurs modifiés :', style: TextStyle(color: Colors.white70)),
                                        const SizedBox(height: 12),
                                        ...differences
                                ]
                        ),
                        actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Valider'))
                        ]
                )
        );

        if (confirmed != true) {
                // Annulation explicite
                throw CancelledException();
        }

        // 3) Envoi de la configuration
        return await messageService.sendSensorConfig(
                List<bool>.generate(16, (i) => (newMask & (1 << i)) != 0)
        );
}