/// Affiche le titre + code du capteur et un bouton pour fermer la popup.

import '../../utils/constants.dart';
import 'package:flutter/material.dart';

class SensorDetailsHeader extends StatelessWidget {
        final String? title;
        final String? code;
        final VoidCallback onClose;

        const SensorDetailsHeader({
                super.key,
                this.title,
                this.code,
                required this.onClose
        });

        @override
        Widget build(BuildContext context) {
                return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                                color: Color(0xFF403B3B),
                                borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16), topRight: Radius.circular(16)
                                )
                        ),
                        child: Row(
                                children: [
                                        Expanded(
                                                child: Text(
                                                        (title ?? 'Détails du capteur') + (code != null ? ' ($code)' : ''),
                                                        style: const TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                                )
                                        ),
                                        GestureDetector(onTap: onClose, child: const Icon(Icons.close, color: Colors.red, size: 30))
                                ]
                        )
                );
        }
}