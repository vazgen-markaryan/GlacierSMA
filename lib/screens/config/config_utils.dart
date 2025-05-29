import 'config_custom_sensor.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Exception levée quand l’utilisateur annule la confirmation
class CancelledException implements Exception {
}

/// Résultat du parsing CSV pour la config série.
class SeriesParams {
        final int sleep;
        final double seaPressure;
        final int capture;
        SeriesParams(this.sleep, this.seaPressure, this.capture);
}

/// Parse les champs « sleep_minutes », « sea_level_pressure », « capture_amount ».
SeriesParams parseSeriesParams(RawData raw) {
        final m = raw.asMap;
        return SeriesParams(
                int.tryParse(m['sleep_minutes'] ?? '') ?? 0,
                double.tryParse(m['sea_level_pressure'] ?? '') ?? 0,
                int.tryParse(m['capture_amount'] ?? '') ?? 0
        );
}

/// Clamp + validation
int validateSleep(int v) => v.clamp(0, 1440);
bool isSleepInvalid(int v) => v < 0 || v > 1440;
int validateCapture(int v) => v.clamp(0, 255);
bool isCaptureInvalid(int v) => v < 0 || v > 255;

/// Envoie la config de masques (16 bits). Renvoie true si OK.
Future<bool> sendMaskConfig({
        required BuildContext context,
        required int initialMask,
        required int newMask,
        required MessageService svc
}) {
        return submitConfiguration(
                context: context,
                initialMask: initialMask,
                newMask: newMask,
                messageService: svc
        );
}

/// Envoie les paramètres série S, P, C si modifiés.
/// Met à jour les init* par callbacks et renvoie true si tous OK.
Future<bool> sendSeriesConfig({
        required MessageService svc,
        required int sleep,
        required int initSleep,
        required void Function(int) updateInitSleep,
        required double sea,
        required double initSea,
        required void Function(double) updateInitSea,
        required int capture,
        required int initCapture,
        required void Function(int) updateInitCapture
}) async {
        if (sleep != initSleep) {
                if (!await svc.sendConfigInteger('S', sleep)) return false;
                updateInitSleep(sleep);
        }
        if (sea != initSea) {
                if (!await svc.sendConfigDouble('P', sea)) return false;
                updateInitSea(sea);
        }
        if (capture != initCapture) {
                if (!await svc.sendConfigInteger('C', capture)) return false;
                updateInitCapture(capture);
        }
        return true;
}

/// Réinitialise aux valeurs par défaut via heartbeat.
Future<bool> resetToDefaults(MessageService svc) =>
svc.sendString('<default-settings>');

/// Affiche un popup “Mot de passe requis”
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
                                                        title: tr('config.password_required'),
                                                        content: TextField(
                                                                controller: controller,
                                                                obscureText: true,
                                                                decoration: InputDecoration(
                                                                        labelText: tr('config.password'),
                                                                        errorText: errorText
                                                                )
                                                        ),
                                                        actions: [
                                                                TextButton(
                                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                                        child: Text(tr('config.quit'))
                                                                ),
                                                                TextButton(
                                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                                        child: Text(tr('config.validate'))
                                                                )
                                                        ]
                                                )
                                        );
                                }
                        )
                );

                if (result != true) return false;
                if (controller.text == motDePasse) return true;

                // Affiche l’erreur et recommence
                errorText = tr('config.invalid_password');
                controller.clear();
        }
}

/// Affiche un popup “Quitter sans enregistrer?”
Future<bool> showDiscardDialog(BuildContext context) async {
        final leave = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => CustomPopup(
                        title: tr('config.unsaved_changes_title'),
                        content: Text(tr('config.unsaved_changes_content')),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: Text(tr('no'))
                                ),
                                TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: Text(tr('yes'))
                                )
                        ]
                )
        );
        return leave == true;
}

/// Construit la liste des différences, affiche la confirmation BIOS-style
/// Envoie la config si validé.
/// Lance CancelledException si l’utilisateur annule la confirmation.
Future<bool> submitConfiguration({
        required BuildContext context,
        required int initialMask,
        required int newMask,
        required MessageService messageService
}) async {
        // Les lignes de différence
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
                                        code: s.codeName,
                                        place: s.placement,
                                        oldStatus: oldOn,
                                        newStatus: newOn
                                )
                        );
                }
        }

        // Popup de confirmation
        final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CustomPopup(
                        title: tr('config.confirm_title'),
                        content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        Text(tr('config.modified_sensors'), style: const TextStyle(color: Colors.white70)),
                                        const SizedBox(height: 12),
                                        ...differences
                                ]
                        ),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(tr('config.cancel'))
                                ),
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text(tr('config.confirm'))
                                )
                        ]
                )
        );

        if (confirmed != true) {
                throw CancelledException();
        }

        // 3) Envoi de la config
        return await messageService.sendSensorConfig(
                List<bool>.generate(16, (i) => (newMask & (1 << i)) != 0)
        );
}