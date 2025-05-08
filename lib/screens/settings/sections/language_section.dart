import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

/// Section « Langue » stylée comme une ExpansionTile, avec drapeaux + labels colorés.
class LanguageSection extends StatelessWidget {
        const LanguageSection({Key? key}) : super(key: key);

        String localeLabel(Locale locale) {
                switch (locale.languageCode) {
                        case 'en':
                                return 'English';
                        case 'fr':
                                return 'Français';
                        case 'es':
                                return 'Español';
                        default:
                        return locale.toLanguageTag();
                }
        }

        @override
        Widget build(BuildContext context) {
                final current = context.locale;

                return ExpansionTile(
                        // même padding horizontal que dans AboutSection
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        // même padding pour le contenu déroulant
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),

                        leading: const Icon(Icons.language),
                        title: Text(tr('language')),

                        children: [
                                Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: context.supportedLocales.map((locale) {
                                                        final isSelected = locale == current;
                                                        return GestureDetector(
                                                                onTap: () => context.setLocale(locale),
                                                                child: Column(
                                                                        children: [
                                                                                SvgPicture.asset(
                                                                                        'assets/icons/${locale.languageCode}.svg',
                                                                                        width: 48,
                                                                                        height: 48
                                                                                ),
                                                                                const SizedBox(height: 4),
                                                                                Text(
                                                                                        localeLabel(locale),
                                                                                        style: TextStyle(
                                                                                                color: isSelected ? Colors.green : Colors.red,
                                                                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                                                                fontSize: 14
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
                );
        }
}