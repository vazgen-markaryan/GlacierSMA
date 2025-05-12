import 'config_utils.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';

enum ConfigButtonStateEnum { idle, success, failure }

class ConfigButton extends StatefulWidget {
        final ValueNotifier<int> localMaskNotifier;
        final int initialMask;
        final ValueNotifier<int?> activeMaskNotifier;
        final MessageService messageService;
        final bool isEnabled;
        final VoidCallback? onSuccess;

        const ConfigButton({
                Key? key,
                required this.localMaskNotifier,
                required this.initialMask,
                required this.activeMaskNotifier,
                required this.messageService,
                required this.isEnabled,
                this.onSuccess
        }) : super(key: key);

        @override
        State<ConfigButton> createState() => ConfigButtonState();
}

class ConfigButtonState extends State<ConfigButton> {
        ConfigButtonStateEnum state = ConfigButtonStateEnum.idle;

        @override
        Widget build(BuildContext context) {
                return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                                onPressed: (state == ConfigButtonStateEnum.idle && widget.isEnabled)
                                        ? handleTap
                                        : null,
                                icon: Icon(
                                        state == ConfigButtonStateEnum.idle
                                                ? Icons.send
                                                : state == ConfigButtonStateEnum.success
                                                        ? Icons.check_circle
                                                        : Icons.error,
                                        color: Colors.white
                                ),
                                label: Text(
                                        state == ConfigButtonStateEnum.idle
                                                ? tr('config.config_apply')
                                                : state == ConfigButtonStateEnum.success
                                                        ? tr('config.config_saved')
                                                        : tr('config.config_failed'),
                                        style: const TextStyle(color: Colors.white)
                                ),
                                style: ElevatedButton.styleFrom(
                                        backgroundColor: state == ConfigButtonStateEnum.idle
                                                ? Theme.of(context).primaryColor
                                                : state == ConfigButtonStateEnum.success
                                                        ? Colors.green.withOpacity(0.8)
                                                        : Colors.red.withOpacity(0.8)
                                )
                        )
                );
        }

        Future<void> handleTap() async {
                bool ok = false;

                try {
                        ok = await submitConfiguration(
                                context: context,
                                initialMask: widget.initialMask,
                                newMask: widget.localMaskNotifier.value,
                                messageService: widget.messageService
                        );
                }
                on CancelledException {
                        // Utilisateur a annulé → on ne change rien
                        return;
                }

                // Affiche Succès ou Échec
                setState(() => state = ok
                                ? ConfigButtonStateEnum.success
                                : ConfigButtonStateEnum.failure);

                if (ok) {
                        widget.activeMaskNotifier.value = widget.localMaskNotifier.value;
                        widget.onSuccess?.call();
                }

                // Reset button state après 1 seconde
                await Future.delayed(const Duration(seconds: 1));
                if (!mounted) return;
                setState(() => state = ConfigButtonStateEnum.idle);
        }
}