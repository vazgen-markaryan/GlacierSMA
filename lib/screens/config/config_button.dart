import 'package:flutter/material.dart';

/// États internes du bouton
enum ConfigButtonStateEnum {
        idle, submitting, success, failure }

/// Un bouton qui gère son propre feedback visuel (chargement, succès, échec)
/// Empêche le spam pendant l'opération.
class ConfigButton extends StatefulWidget {

        /// Appelé lors du clic. Doit renvoyer `true` ou `false` selon la réussite.
        final Future<bool> Function() onSubmit;

        final String idleLabel;
        final String submittingLabel;
        final String successLabel;
        final String failureLabel;

        const ConfigButton({
                Key? key,
                required this.onSubmit,
                this.idleLabel = 'Envoyer',
                this.submittingLabel = 'Patientez...',
                this.successLabel = 'Succès',
                this.failureLabel = 'Échec'
        }) : super(key: key);

        @override
        State<ConfigButton> createState() => ConfigButtonState();
}

class ConfigButtonState extends State<ConfigButton> {
        ConfigButtonStateEnum state = ConfigButtonStateEnum.idle;

        @override
        Widget build(BuildContext context) {
                switch (state) {
                        case ConfigButtonStateEnum.idle:
                                return buildButton(
                                        widget.idleLabel,
                                        Icons.send,
                                        Theme.of(context).primaryColor,
                                        handleTap
                                );
                        case ConfigButtonStateEnum.submitting:
                                return buildButton(
                                        widget.submittingLabel,
                                        Icons.hourglass_top,
                                        Theme.of(context).primaryColor.withAlpha(180),
                                        null
                                );
                        case ConfigButtonStateEnum.success:
                                return buildButton(
                                        widget.successLabel,
                                        Icons.check_circle,
                                        Colors.green.withOpacity(0.8),
                                        null
                                );
                        case ConfigButtonStateEnum.failure:
                                return buildButton(
                                        widget.failureLabel,
                                        Icons.error,
                                        Colors.red.withOpacity(0.8),
                                        null
                                );
                }
        }

        Future<void> handleTap() async {
                setState(() => state = ConfigButtonStateEnum.submitting);
                final ok = await widget.onSubmit();
                // Affiche Success/Failure puis réactive immédiatement le bouton
                setState(() => state = ok
                                ? ConfigButtonStateEnum.success
                                : ConfigButtonStateEnum.failure);
                if (!mounted) return;
                setState(() => state = ConfigButtonStateEnum.idle);
        }

        Widget buildButton(String label, IconData icon, Color color, VoidCallback? onTap) =>
        SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: Icon(icon, color: Colors.white),
                        label: Text(label, style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: color)
                )
        );
}