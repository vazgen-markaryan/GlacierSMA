import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/sections/other_section.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/sections/language_section.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';

class SettingsScreen extends StatelessWidget {
        final ValueNotifier<RawData?> firmwareNotifier;
        final ValueNotifier<int> iterationNotifier;

        const SettingsScreen({
                Key? key,
                required this.firmwareNotifier,
                required this.iterationNotifier
        }) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        body: LayoutBuilder(
                                builder: (context, constraints) {
                                        return SingleChildScrollView(
                                                padding: const EdgeInsets.all(16),
                                                child: ConstrainedBox(
                                                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                                        child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        LanguageSection(),

                                                                        const SizedBox(height: 8),

                                                                        OtherSection(
                                                                                firmwareNotifier: firmwareNotifier,
                                                                                iterationNotifier: iterationNotifier
                                                                        )
                                                                ]
                                                        )
                                                )
                                        );
                                }
                        )
                );
        }
}