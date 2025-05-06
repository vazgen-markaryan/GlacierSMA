import 'package:flutter/material.dart';

/// Exception levée quand l’utilisateur annule la confirmation
class CancelledException implements Exception {
}

/// État interne du bouton
enum ConfigButtonStateEnum {
        idle, success, failure }

/// Bouton qui gère son propre feedback (succès/échec) après exécution.
/// Ne passe plus en “chargement” — le chargement est géré par un overlay global.
class ConfigButton extends StatefulWidget {
        /// Doit renvoyer `true` si la config a été appliquée, `false` sinon.
        /// Peut lancer [CancelledException] pour annuler proprement sans afficher d’erreur.
        final Future<bool> Function() onSubmit;

        final String idleLabel;
        final String successLabel;
        final String failureLabel;

        const ConfigButton({
                Key? key,
                required this.onSubmit,
                this.idleLabel = 'Appliquer la configuration',
                this.successLabel = 'Enregistré',
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
                try {
                        final ok = await widget.onSubmit();
                        // Affiche succès ou échec
                        setState(() => state = ok
                                        ? ConfigButtonStateEnum.success
                                        : ConfigButtonStateEnum.failure);
                }
                on CancelledException {
                        // Annulation : on ne passe ni en échec, ni en chargement
                        return;
                }

                // Après 1s, on revient en idle
                await Future.delayed(const Duration(seconds: 1));
                if (!mounted) return;
                setState(() => state = ConfigButtonStateEnum.idle);
        }

        Widget buildButton(
                String label,
                IconData icon,
                Color color,
                VoidCallback? onTap
        ) {
                return SizedBox(
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
}