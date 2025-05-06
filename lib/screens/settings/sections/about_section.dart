import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_section.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_widgets.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Section "À propos" affichant les infos du firmware
class AboutSection extends StatelessWidget {
        final ValueNotifier<RawData?> firmwareNotifier;

        const AboutSection({Key? key, required this.firmwareNotifier}) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return SettingsSection(
                        title: 'À propos',
                        children: [
                                ValueListenableBuilder<RawData?>(
                                        valueListenable: firmwareNotifier,
                                        builder: (ctx, data, _) {
                                                if (data == null) {
                                                        // Données non encore reçues
                                                        return const ListTile(
                                                                leading: Icon(Icons.info_outline),
                                                                title: Text('À propos'),
                                                                subtitle: Text("En attente de données..."),
                                                                trailing: Icon(Icons.arrow_forward_ios)
                                                        );
                                                }
                                                // Extraction des champs
                                                final name = data.values[0];
                                                final repo = data.values[1];
                                                final hash = data.values[2];
                                                final dirty = data.values[3] == '1';
                                                final ts = int.tryParse(data.values[4]) ?? 0;
                                                final buildD = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                                                final user = data.values[5];
                                                final email = data.values[6];
                                                final repoUrl = '$repo/tree/$hash';

                                                return ExpansionTile(
                                                        leading: const Icon(Icons.info_outline),
                                                        title: const Text('À propos'),
                                                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        children: [
                                                                LabelRow(label: 'Micrologiciel', value: name),
                                                                LinkRow(
                                                                        label: 'Repository Git',
                                                                        url: repoUrl,
                                                                        onError: () {
                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                        const SnackBar(content: Text("Impossible d'ouvrir le lien"))
                                                                                );
                                                                        }
                                                                ),
                                                                LabelRow(label: 'Commit', value: dirty ? 'Modifié' : 'Exact'),
                                                                LabelRow(
                                                                        label: 'Compilé le',
                                                                        value: '${buildD.day.toString().padLeft(2, '0')}/'
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