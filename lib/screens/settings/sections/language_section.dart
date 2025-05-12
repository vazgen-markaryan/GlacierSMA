import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/screens/settings/settings_section.dart';

/// Section « Langue » dans les paramètres, stylisée comme une ExpansionTile.
/// Affiche les drapeaux et labels des langues prises en charge, avec l’option de sélectionner la locale active.
class LanguageSection extends StatefulWidget {
        const LanguageSection({Key? key}) : super(key: key);

        @override
        LanguageSectionState createState() => LanguageSectionState();
}

class LanguageSectionState extends State<LanguageSection> {
        bool expanded = false;

        @override
        Widget build(BuildContext context) {
                final current = context.locale;

                return SettingsSection(
                        title: tr('settings.language.title'),
                        children: [
                                ExpansionTile(
                                        leading: const Icon(Icons.language),
                                        title: Text(tr('settings.language.title')),
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        childrenPadding:
                                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        controlAffinity: ListTileControlAffinity.trailing,
                                        onExpansionChanged: (open) => setState(() => expanded = open),
                                        children: [
                                                Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: context.supportedLocales.map(
                                                                (locale) {
                                                                        final isSelected = locale == current;
                                                                        return GestureDetector(
                                                                                onTap: () => context.setLocale(locale),
                                                                                child: Column(
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                                SvgPicture.asset(
                                                                                                        'assets/icons/${locale.languageCode}.svg',
                                                                                                        width: 48,
                                                                                                        height: 48
                                                                                                ),
                                                                                                const SizedBox(height: 4),
                                                                                                Text(
                                                                                                        tr('settings.language.${locale.languageCode}'),
                                                                                                        style: TextStyle(
                                                                                                                color: isSelected ? Colors.green : Colors.red,
                                                                                                                fontSize: 14,
                                                                                                                fontWeight:
                                                                                                                isSelected ? FontWeight.bold : FontWeight.normal
                                                                                                        )
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        );
                                                                }
                                                        ).toList()
                                                ),
                                                const SizedBox(height: 8.0)
                                        ]
                                )
                        ]
                );
        }
}