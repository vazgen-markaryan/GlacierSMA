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
        final int sleepTime;
        final double seaPressure;
        final int capture;
        final int iridiumMode;
        SeriesParams(this.sleepTime, this.seaPressure, this.capture, this.iridiumMode);
}

/// Parse les champs « sleep_minutes », « sea_level_pressure », « capture_amount ».
SeriesParams parseSeriesParams(RawData raw) {
        final map = raw.asMap;
        return SeriesParams(
                int.tryParse(map['sleep_minutes'] ?? '') ?? 0,
                double.tryParse(map['sea_level_pressure'] ?? '') ?? 0,
                int.tryParse(map['capture_amount'] ?? '') ?? 0,
                int.tryParse(map['iridium_signalcheck'] ?? '') ?? 0
        );
}

/// Clamp + validation
int validateSleep(int value) => value.clamp(0, 1440);
bool isSleepInvalid(int value) => value < 0 || value > 1440;
int validateCapture(int value) => value.clamp(0, 255);
bool isCaptureInvalid(int value) => value < 0 || value > 255;

/// Envoie la config de masques (16 bits). Renvoie true si OK.
Future<bool> sendMaskConfig({
        required BuildContext context,
        required int initialMask,
        required int newMask,
        required MessageService messageService
}) {
        return submitConfiguration(
                context: context,
                initialMask: initialMask,
                newMask: newMask,
                messageService: messageService
        );
}

/// Envoie les paramètres série S, P, C, I si modifiés.
/// Met à jour les init* par callbacks et renvoie true si tous OK.
Future<bool> sendSeriesConfig({
        required MessageService messageService,
        required int sleep,
        required int initSleep,
        required void Function(int) updateInitSleep,
        required double seaPressure,
        required double initSeaPressure,
        required void Function(double) updateInitSeaPressure,
        required int captureAmount,
        required int initCaptureAmount,
        required void Function(int) updateInitCaptureAmount,
        required int iridiumMode,
        required int initIridiumMode,
        required void Function(int) updateInitIridiumMode
}) async {
        if (sleep != initSleep) {
                if (!await messageService.sendConfigInteger('S', sleep)) return false;
                updateInitSleep(sleep);
        }
        if (seaPressure != initSeaPressure) {
                if (!await messageService.sendConfigDouble('P', seaPressure)) return false;
                updateInitSeaPressure(seaPressure);
        }
        if (captureAmount != initCaptureAmount) {
                if (!await messageService.sendConfigInteger('C', captureAmount)) return false;
                updateInitCaptureAmount(captureAmount);
        }
        if (iridiumMode != initIridiumMode) {
                if (!await messageService.sendConfigInteger('I', iridiumMode)) return false;
                updateInitIridiumMode(iridiumMode);
        }
        return true;
}

/// Réinitialise aux valeurs par défaut via heartbeat.
Future<bool> resetToDefaults(MessageService messageService) => messageService.sendString('<default-settings>');

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
                        builder: (context) => StatefulBuilder(builder: (context, setState) {
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
                                                                        onPressed: () => Navigator.of(context).pop(false),
                                                                        child: Text(tr('config.quit'))
                                                                ),
                                                                TextButton(
                                                                        onPressed: () => Navigator.of(context).pop(true),
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
                builder: (context) => CustomPopup(
                        title: tr('config.unsaved_changes_title'),
                        content: Text(tr('config.unsaved_changes_content')),
                        actions: [
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(tr('no'))
                                ),
                                TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
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
        for (final sensor in allSensors.where((sensor) => sensor.bitIndex != null)) {
                final bit = sensor.bitIndex!;
                final oldOn = (initialMask & (1 << bit)) != 0;
                final newOn = (newMask & (1 << bit)) != 0;
                if (oldOn != newOn) {
                        differences.add(
                                ConfigCustomSensor(
                                        svgIcon: sensor.svgIcon!,
                                        title: sensor.title!,
                                        bus: sensor.bus,
                                        code: sensor.codeName,
                                        place: sensor.placement,
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

        // Envoi de la config
        return await messageService.sendSensorConfig(
                List<bool>.generate(16, (i) => (newMask & (1 << i)) != 0)
        );
}