import 'package:flutter/material.dart';

/// Regroupe un titre de section et sa liste de widgets enfants
class SettingsDiv extends StatelessWidget {
        final String title;
        final List<Widget> children;

        const SettingsDiv({
                Key? key,
                required this.title,
                required this.children
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                Text(
                                        title,
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)
                                ),
                                const SizedBox(height: 12),
                                ...children
                        ]
                );
        }
}