/// Bouton pour envoyer un message custom sur le port série.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';

class SendMessageButton extends StatelessWidget {
        final Future<bool> Function(String, Uint8List) sendOnOffMessage;

        const SendMessageButton({
                super.key,
                required this.sendOnOffMessage
        });

        @override
        Widget build(BuildContext context) {
                return Center(
                        child: ElevatedButton(
                                onPressed: () async {
                                        final success = await sendOnOffMessage('<active>', Uint8List.fromList([0xff, 0xff]));
                                        showCustomSnackBar(
                                                context,
                                                message: success ? 'Message envoyé' : 'Échec de l’envoi du message.',
                                                iconData: success ? Icons.check_circle : Icons.error,
                                                backgroundColor: success ? Colors.green : Colors.red,
                                                textColor: Colors.white,
                                                iconColor: Colors.white,
                                                duration: const Duration(seconds: 3)
                                        );
                                },
                                style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                                ),
                                child: const Text(
                                        'Envoyer Message',
                                        style: TextStyle(fontSize: 16)
                                )
                        )
                );
        }
}