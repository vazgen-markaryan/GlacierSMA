import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';

/// Tile d'expansion insérée dans OtherSection.
class DevCreditsTile extends StatelessWidget {
        const DevCreditsTile({super.key});

        @override
        Widget build(BuildContext context) {
                return ExpansionTile(
                        leading: const Icon(Icons.people_alt_outlined),
                        title: Text(tr('settings.dev_credits.title')),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                                SingleDevCard(
                                        role: tr('settings.dev_credits.frontend_developer'),
                                        name: 'Vazgen Markaryan',
                                        githubUrl: 'https://github.com/vazgen-markaryan',
                                        linkedinUrl: 'https://linkedin.com/in/vazgen-markaryan/',
                                        githubIconAsset: 'assets/icons/github.svg',
                                        linkedinIconAsset: 'assets/icons/linkedin.svg'
                                ),
                                SizedBox(height: 20),
                                SingleDevCard(
                                        role: tr('settings.dev_credits.backend_developer'),
                                        name: 'Nathan Marien',
                                        githubUrl: 'https://github.com/nathannino',
                                        linkedinUrl: 'https://www.linkedin.com/in/nathan-marien-54118b309/',
                                        githubIconAsset: 'assets/icons/github.svg',
                                        linkedinIconAsset: 'assets/icons/linkedin.svg'
                                )
                        ]
                );
        }
}

/// Bloc individuel pour un développeur, centré, avec rôle, nom, GitHub et LinkedIn.
class SingleDevCard extends StatelessWidget {
        final String role;
        final String name;
        final String githubUrl;
        final String linkedinUrl;
        final String githubIconAsset;
        final String linkedinIconAsset;

        const SingleDevCard({
                super.key,
                required this.role,
                required this.name,
                required this.githubUrl,
                required this.linkedinUrl,
                required this.githubIconAsset,
                required this.linkedinIconAsset
        });

        Widget buildIcon(BuildContext context, String url, String assetPath, String tooltip) {
                return IconButton(
                        onPressed: () async {
                                final ok = await launchUrlString(url);
                                if (!ok) {
                                        showCustomSnackBar(
                                                context,
                                                message: tr('settings.dev_credits.cant_open ') + tooltip + '.',
                                                iconData: Icons.error,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                iconColor: Colors.white
                                        );
                                }
                        },
                        icon: SvgPicture.asset(
                                assetPath,
                                width: 48,
                                height: 48
                        ),
                        splashRadius: 32,
                        tooltip: tooltip
                );
        }

        @override
        Widget build(BuildContext context) {
                return Center(
                        child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                        Text(
                                                role,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                textAlign: TextAlign.center
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                                name,
                                                style: const TextStyle(fontSize: 15),
                                                textAlign: TextAlign.center
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                        buildIcon(context, githubUrl, githubIconAsset, 'GitHub'),
                                                        const SizedBox(width: 16),
                                                        buildIcon(context, linkedinUrl, linkedinIconAsset, 'LinkedIn')
                                                ]
                                        )
                                ]
                        )
                );
        }
}