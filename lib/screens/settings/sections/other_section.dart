import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/dev_credits.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_div.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_widgets.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/test_tutorial_switch.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Section "Autres" qui contient toutes les options additionnelles
/// Affiche un ExpansionTile détaillant les informations du firmware
class OtherSection extends StatelessWidget {
        /// Notifier contenant les données RawData reçues depuis le bloc `<id>`
        final ValueNotifier<RawData?> firmwareNotifier;

        /// Notifier pour l'itération actuelle, utilisé pour afficher le nombre d'itérations
        final ValueNotifier<int> iterationNotifier;

        const OtherSection({
                Key? key, 
                required this.firmwareNotifier,
                required this.iterationNotifier
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return SettingsDiv(
                        title: tr('settings.others'),
                        children: [
                                TestTutorialSwitch(),

                                ValueListenableBuilder<RawData?>(
                                        valueListenable: firmwareNotifier,
                                        builder: (ctx, data, _) {
                                                // Récupère le map header→valeur sinon null
                                                final info = data?.asMap;
                                                // Extraction des champs par header
                                                final name = info?['name'] ?? '';
                                                final code = info?['code'] ?? '';
                                                final repo = info?['url'] ?? '';
                                                final hash = info?['hash'] ?? '';
                                                final dirty = info?['dirty'] == '1';
                                                final timeSeconds = int.tryParse(info?['date'] ?? '') ?? 0;
                                                final buildDate = DateTime.fromMillisecondsSinceEpoch(timeSeconds * 1000);
                                                final user = info?['user'] ?? '';
                                                final email = info?['email'] ?? '';
                                                final repoUrl = '$repo/tree/$hash';

                                                // Affiche un ExpansionTile contenant les infos
                                                return ExpansionTile(
                                                        leading: const Icon(Icons.info_outline),
                                                        // titre de l'expansion
                                                        title: Text(tr('settings.about.title')),
                                                        childrenPadding:
                                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        children: [
                                                                LabelRow(
                                                                        label: tr('settings.about.station_name'),
                                                                        value: name
                                                                ),
                                                                LabelRow(
                                                                        label: tr('settings.about.firmware'),
                                                                        value: code
                                                                ),
                                                                LinkRow(
                                                                        label: tr('settings.about.github'),
                                                                        url: repoUrl,
                                                                        onError: () => showCustomSnackBar(
                                                                                context,
                                                                                message: tr('settings.about.github_error'),
                                                                                iconData: Icons.error,
                                                                                backgroundColor: Colors.red,
                                                                                textColor: Colors.white,
                                                                                iconColor: Colors.white
                                                                        )
                                                                ),
                                                                LabelRow(
                                                                        label: tr('settings.about.code'),
                                                                        value: dirty
                                                                                ? tr('settings.about.commit_modified')
                                                                                : tr('settings.about.commit_ok')
                                                                ),
                                                                LabelRow(
                                                                        label: tr('settings.about.compiled_on'),
                                                                        value:
                                                                        '${buildDate.day.toString().padLeft(2, '0')}/'
                                                                        '${buildDate.month.toString().padLeft(2, '0')}/'
                                                                        '${buildDate.year} '
                                                                        '${buildDate.hour.toString().padLeft(2, '0')}:'
                                                                        '${buildDate.minute.toString().padLeft(2, '0')}'
                                                                ),
                                                                LabelRow(
                                                                        label: tr('settings.about.compiled_by'),
                                                                        value: user
                                                                ),
                                                                LabelRow(
                                                                        label: tr('settings.about.contact'),
                                                                        value: email
                                                                ),

                                                                ValueListenableBuilder<int>(
                                                                        valueListenable: iterationNotifier,
                                                                        builder: (context, iteration, _) {
                                                                                return LabelRow(
                                                                                        label: tr('settings.iteration_count'),
                                                                                        value: iteration.toString()
                                                                                );
                                                                        }
                                                                )
                                                        ]
                                                );
                                        }
                                ),

                                DevCreditsTile()
                        ]
                );
        }
}