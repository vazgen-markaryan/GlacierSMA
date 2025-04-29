/// Affiche le titre + code du capteur et un bouton pour fermer la popup.

import 'package:flutter/material.dart';

class SensorPopupHeader extends StatelessWidget {
        final String? title;
        final String? code;
        final VoidCallback onClose;

        const SensorPopupHeader({
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
                                        GestureDetector(onTap: onClose, child: const Icon(Icons.close, color: Colors.red, size: 30))
                                ]
                        )
                );
        }
}