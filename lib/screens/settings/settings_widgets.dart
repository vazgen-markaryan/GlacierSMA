import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Ligne simple "Label : Valeur"
class LabelRow extends StatelessWidget {
        final String label;
        final String value;

        const LabelRow({Key? key, required this.label, required this.value})
                : super(key: key);

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

/// Ligne avec un bouton ouvrant une url
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
                                                        style: TextStyle(
                                                                color: Colors.blueAccent,
                                                                decoration: TextDecoration.none
                                                        )
                                                )
                                        )
                                ]
                        )
                );
        }
}