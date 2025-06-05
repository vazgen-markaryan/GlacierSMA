import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
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
                        body: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                LanguageSection(),
                                                const SizedBox(height: defaultPadding),
                                                OtherSection(firmwareNotifier: firmwareNotifier)
                                        ]
                                )
                        ),
                        bottomNavigationBar: ValueListenableBuilder<int>(
                                valueListenable: iterationNotifier,
                                builder: (context, iteration, _) {
                                        return Container(
                                                color: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                                const Icon(Icons.repeat),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                        tr('settings.iteration_count', namedArgs: {'iteration': iteration.toString()}),
                                                                        style: const TextStyle(fontWeight: FontWeight.bold)
                                                                )
                                                        ]
                                                )
                                        );
                                }
                        )
                );
        }
}