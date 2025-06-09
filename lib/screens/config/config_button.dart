import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';

/// États internes du bouton
enum ConfigButtonStateEnum {
        idle, loading, success, failure 
}

/// Bouton générique avec confirmation facultative, spinner interne et feedback visuel
class ConfigButton extends StatefulWidget {
        final Future<bool> Function() action;
        final String idleLabel;
        final String loadingLabel;
        final String successLabel;
        final String failureLabel;
        final IconData idleIcon;
        final IconData successIcon;
        final IconData failureIcon;
        final Color idleColor;
        final Color successColor;
        final Color failureColor;
        final bool enabled;
        final bool skipConfirmation;
        final String? confirmTitle;
        final String? confirmContent;

        const ConfigButton({
                Key? key,
                this.confirmTitle,
                this.confirmContent,
                this.loadingLabel = '…',
                this.enabled = true,
                this.skipConfirmation = false,
                required this.action,
                required this.idleLabel,
                required this.successLabel,
                required this.failureLabel,
                required this.idleIcon,
                required this.successIcon,
                required this.failureIcon,
                required this.idleColor,
                required this.successColor,
                required this.failureColor
        }) : assert(
                skipConfirmation || (confirmTitle != null && confirmContent != null), 'Si skipConfirmation est à false, confirmTitle et confirmContent doivent être fournis'),
                super(key: key);

        @override
        ConfigButtonState createState() => ConfigButtonState();
}

class ConfigButtonState extends State<ConfigButton> {
        ConfigButtonStateEnum state = ConfigButtonStateEnum.idle;

        @override
        Widget build(BuildContext context) {
                final canTap = state == ConfigButtonStateEnum.idle && widget.enabled;

                return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                                onPressed: canTap ? handleTap : null,
                                icon: state == ConfigButtonStateEnum.loading
                                        ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                        )
                                        : Icon(
                                                state == ConfigButtonStateEnum.idle
                                                        ? widget.idleIcon
                                                        : state == ConfigButtonStateEnum.success
                                                                ? widget.successIcon
                                                                : widget.failureIcon,
                                                color: Colors.white
                                        ),
                                label: Text(
                                        state == ConfigButtonStateEnum.idle
                                                ? widget.idleLabel
                                                : state == ConfigButtonStateEnum.loading
                                                        ? widget.loadingLabel
                                                        : state == ConfigButtonStateEnum.success
                                                                ? widget.successLabel
                                                                : widget.failureLabel,
                                        style: const TextStyle(color: Colors.white)
                                ),
                                style: ButtonStyle(

                                        // La couleur de fond en fonction de l'état interne, sans tenir compte de MaterialState.disabled
                                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                                        switch (state) {
                                                                case ConfigButtonStateEnum.success:
                                                                        return widget.successColor;
                                                                case ConfigButtonStateEnum.failure:
                                                                        return widget.failureColor;
                                                                case ConfigButtonStateEnum.loading:
                                                                        return widget.idleColor;
                                                                case ConfigButtonStateEnum.idle:
                                                                        // Si on est à l'état idle mais que enabled=false, on retombe sur gris
                                                                        return widget.enabled ? widget.idleColor : Colors.grey;
                                                        }
                                                }
                                        ),
                                        foregroundColor: WidgetStateProperty.all(Colors.white)
                                )
                        )
                );
        }

        Future<void> handleTap() async {
                // Si on ne skip pas, on requiert confirmTitle & confirmContent
                if (!widget.skipConfirmation) {
                        final confirmed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => CustomPopup(
                                        title: widget.confirmTitle!,
                                        content: Text(widget.confirmContent!),
                                        actions: [
                                                TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: Text(tr("config.cancel"))
                                                ),
                                                TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: Text(tr("config.confirm"))
                                                )
                                        ]
                                )
                        );
                        if (confirmed != true) return;
                }

                // Passage en mode chargement
                setState(() => state = ConfigButtonStateEnum.loading);

                // Exécution de l'action
                bool ok = false;
                try {
                        ok = await widget.action();
                }
                catch (_) {
                        ok = false;
                }

                // Feedback visuel
                setState(() => state = ok ? ConfigButtonStateEnum.success : ConfigButtonStateEnum.failure);

                // Retour à l'état idle après un délai
                await Future.delayed(const Duration(seconds: 2));
                if (!mounted) return;
                setState(() => state = ConfigButtonStateEnum.idle);
        }
}