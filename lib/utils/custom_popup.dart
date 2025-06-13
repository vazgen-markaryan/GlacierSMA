import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';

/// Widget pour afficher un popup personnalisé avec un titre, du contenu et des actions
///  Utilisé pour afficher des informations détaillées ou des options supplémentaires dans l'application.
class CustomPopup extends StatelessWidget {
        final String title;
        final Widget content;
        final List<Widget> actions;
        final bool showCloseButton;

        const CustomPopup({
                Key? key,
                required this.title,
                required this.content,
                required this.actions,
                this.showCloseButton = true
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                final ScrollController scrollController = ScrollController();

                return Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: Center(
                                child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                                maxWidth: 500,
                                                maxHeight: 700
                                        ),
                                        child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                        // Header avec titre et icône de fermeture
                                                        Container(
                                                                width: double.infinity,
                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                                decoration: const BoxDecoration(
                                                                        color: Color(0xFF403B3B),
                                                                        borderRadius: BorderRadius.only(
                                                                                topLeft: Radius.circular(16),
                                                                                topRight: Radius.circular(16)
                                                                        )
                                                                ),
                                                                child: Row(
                                                                        children: [
                                                                                Expanded(
                                                                                        child: Text(
                                                                                                title,
                                                                                                style: const TextStyle(
                                                                                                        color: primaryColor,
                                                                                                        fontSize: 20,
                                                                                                        fontWeight: FontWeight.bold
                                                                                                )
                                                                                        )
                                                                                ),
                                                                                if (showCloseButton)
                                                                                GestureDetector(
                                                                                        onTap: () => Navigator.of(context).pop(),
                                                                                        child: const Icon(
                                                                                                Icons.close,
                                                                                                color: Colors.red,
                                                                                                size: 30
                                                                                        )
                                                                                )
                                                                        ]
                                                                )
                                                        ),

                                                        // Contenu et boutons d'action
                                                        Flexible(
                                                                child: Container(
                                                                        width: double.infinity,
                                                                        decoration: const BoxDecoration(
                                                                                color: secondaryColor,
                                                                                borderRadius: BorderRadius.only(
                                                                                        bottomLeft: Radius.circular(16),
                                                                                        bottomRight: Radius.circular(16)
                                                                                )
                                                                        ),
                                                                        padding: const EdgeInsets.all(20),
                                                                        child: Scrollbar(
                                                                                controller: scrollController,
                                                                                thumbVisibility: true,
                                                                                radius: const Radius.circular(8),
                                                                                thickness: 6,
                                                                                child: SingleChildScrollView(
                                                                                        controller: scrollController,
                                                                                        child: Column(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                children: [
                                                                                                        Container(
                                                                                                                width: double.infinity,
                                                                                                                child: content
                                                                                                        ),
                                                                                                        if (actions.isNotEmpty) ...[
                                                                                                                const SizedBox(height: 16),
                                                                                                                Row(
                                                                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                        children: actions
                                                                                                                )
                                                                                                        ]
                                                                                                ]
                                                                                        )
                                                                                )
                                                                        )
                                                                )
                                                        )
                                                ]
                                        )
                                )
                        )
                );
        }
}