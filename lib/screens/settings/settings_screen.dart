import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Écran Paramètres
class SettingsScreen extends StatelessWidget {
        final ValueNotifier<RawData?> firmwareNotifier;

        const SettingsScreen({
                Key? key,
                required this.firmwareNotifier
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        SettingsSection(
                                                title: 'Random Titre (temporaire)',
                                                children: [
                                                        // About tile avec ExpansionTile
                                                        ValueListenableBuilder<RawData?>(
                                                                valueListenable: firmwareNotifier,
                                                                builder: (ctx, idData, _) {
                                                                        if (idData == null) {
                                                                                return const ListTile(
                                                                                        leading: Icon(Icons.info_outline_rounded),
                                                                                        title: Text('À propos'),
                                                                                        subtitle: Text('En attente de données...'),
                                                                                        trailing: Icon(Icons.arrow_forward_ios)
                                                                                );
                                                                        }
                                                                        final name = idData.values[0];
                                                                        final repo = idData.values[1];
                                                                        final hash = idData.values[2];
                                                                        final dirty = idData.values[3] == '1';
                                                                        final dateS = int.tryParse(idData.values[4]) ?? 0;
                                                                        final buildD = DateTime.fromMillisecondsSinceEpoch(dateS * 1000);
                                                                        final user = idData.values[5];
                                                                        final email = idData.values[6];
                                                                        final repoUrl = '$repo/tree/$hash';

                                                                        return ExpansionTile(
                                                                                leading: const Icon(Icons.info_outline_rounded),
                                                                                title: Text("À propos"),
                                                                                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                                trailing: const Icon(Icons.expand_more),
                                                                                children: [
                                                                                        LabelRow(label: 'Micrologiciel', value: name),
                                                                                        LinkRow(
                                                                                                label: 'GitRepository (Privé)',
                                                                                                url: repoUrl,
                                                                                                onError: () => ScaffoldMessenger.of(context).showSnackBar(
                                                                                                        const SnackBar(content: Text("Impossible d'ouvrir le lien"))
                                                                                                )
                                                                                        ),
                                                                                        LabelRow(label: 'Commit', value: dirty ? 'Modifié' : 'Exacte'),
                                                                                        LabelRow(
                                                                                                label: 'Compilé le',
                                                                                                value:
                                                                                                '${buildD.hour.toString().padLeft(2, '0')}:${buildD.minute.toString().padLeft(2, '0')} '
                                                                                                '${buildD.day.toString().padLeft(2, '0')}/${buildD.month.toString().padLeft(2, '0')}/${buildD.year}'
                                                                                        ),
                                                                                        LabelRow(label: 'Compilé par', value: user),
                                                                                        LabelRow(label: 'Email', value: email)
                                                                                ]
                                                                        );
                                                                }
                                                        )
                                                ]
                                        )
                                ]
                        )
                );
        }
}

/// Widget réutilisable pour les sections avec titre + liste d’enfants
class SettingsSection extends StatelessWidget {
        final String title;
        final List<Widget> children;
        const SettingsSection({
                Key? key,
                required this.title,
                required this.children
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 12),
                                ...children
                        ]
                );
        }
}

/// Ligne “Label : Value”
class LabelRow extends StatelessWidget {
        final String label;
        final String value;
        const LabelRow({Key? key, required this.label, required this.value}) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        Text('$label :', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(value))
                                ]
                        )
                );
        }
}

/// Ligne avec un TextButton ouvrant une URL
class LinkRow extends StatelessWidget {
        final String label;
        final String url;
        final VoidCallback onError;
        const LinkRow({
                Key? key,
                required this.label,
                required this.url,
                required this.onError
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                                children: [
                                        Text('$label :', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        TextButton(
                                                style: TextButton.styleFrom(
                                                        padding: EdgeInsets.zero,
                                                        minimumSize: const Size(0, 0),
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap
                                                ),
                                                onPressed: () async {
                                                        final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
                                                        if (!ok) onError();
                                                },
                                                child: const Text(
                                                        'URL',
                                                        style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.none)
                                                )
                                        )
                                ]
                        )
                );
        }
}