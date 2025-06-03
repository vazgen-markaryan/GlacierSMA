import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/sections/about_section.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/sections/language_section.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/sections/test_tutorial_switch.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

/// Écran principal des Paramètres
class SettingsScreen extends StatelessWidget {
        /// Notifier qui contient les données brute du firmware
        final ValueNotifier<RawData?> firmwareNotifier;

        const SettingsScreen({
                Key? key,
                required this.firmwareNotifier
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                        // Section "Langue"
                                        LanguageSection(),

                                        const SizedBox(height: defaultPadding),

                                        // Section "À propos"
                                        AboutSection(firmwareNotifier: firmwareNotifier),

                                        const SizedBox(height: defaultPadding * 2),
                                        TestTutorialSwitch()
                                ]
                        )
                );
        }
}