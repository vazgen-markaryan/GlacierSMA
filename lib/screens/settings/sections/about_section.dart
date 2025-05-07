import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_section.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_widgets.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Section "À propos"
class AboutSection extends StatelessWidget {
        final ValueNotifier<RawData?> firmwareNotifier;

        const AboutSection({Key? key, required this.firmwareNotifier})
                : super(key: key);

        @override
        Widget build(BuildContext context) {
                return SettingsSection(
                        title: 'Autres',
                        children: [
                                ValueListenableBuilder<RawData?>(
                                        valueListenable: firmwareNotifier,
                                        builder: (ctx, data, _) {
                                                if (data == null) {
                                                        return const ListTile(
                                                                leading: Icon(Icons.info_outline),
                                                                title: Text('À propos'),
                                                                subtitle: Text("En attente de données..."),
                                                                trailing: Icon(Icons.arrow_forward_ios)
                                                        );
                                                }

                                                // On récupère les données par en-tête
                                                final info = data.asMap;
                                                final name = info['name'] ?? '';
                                                final code = info['code'] ?? '';
                                                final repo = info['url'] ?? '';
                                                final hash = info['hash'] ?? '';
                                                final dirty = info['dirty'] == '1';
                                                final ts = int.tryParse(info['date'] ?? '') ?? 0;
                                                final buildD = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                                                final user = info['user'] ?? '';
                                                final email = info['email'] ?? '';
                                                final repoUrl = '$repo/tree/$hash';

                                                return ExpansionTile(
                                                        leading: const Icon(Icons.info_outline),
                                                        title: const Text('À propos'),
                                                        childrenPadding:
                                                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        children: [
                                                                LabelRow(label: 'Nom de la station', value: name),
                                                                LabelRow(label: 'Micrologiciel', value: code),
                                                                LinkRow(
                                                                        label: 'GitHub (Privé)',
                                                                        url: repoUrl,
                                                                        onError: () => showCustomSnackBar(
                                                                                context,
                                                                                message: "Impossible d'ouvrir le lien",
                                                                                iconData: Icons.error,
                                                                                backgroundColor: Colors.red,
                                                                                textColor: Colors.white,
                                                                                iconColor: Colors.white
                                                                        )
                                                                ),
                                                                LabelRow(label: 'Code', value: dirty ? 'Commit était modifié' : 'Correspond au Commit'),
                                                                LabelRow(
                                                                        label: 'Compilé le',
                                                                        value:
                                                                        '${buildD.day.toString().padLeft(2, '0')}/'
                                                                        '${buildD.month.toString().padLeft(2, '0')}/'
                                                                        '${buildD.year} à '
                                                                        '${buildD.hour.toString().padLeft(2, '0')}:'
                                                                        '${buildD.minute.toString().padLeft(2, '0')}'
                                                                ),
                                                                LabelRow(label: 'Compilé par', value: user),
                                                                LabelRow(label: 'Contact', value: email)
                                                        ]
                                                );
                                        }
                                )
                        ]
                );
        }
}