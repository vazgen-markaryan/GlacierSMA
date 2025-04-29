import 'package:flutter/material.dart';

/// Écran Paramètres affichant différentes sections d’options non interactives.
/// Présente des catégories comme Général, Aide et Confidentialité.
class SettingsScreen extends StatelessWidget {
        const SettingsScreen({Key? key}) : super(key: key);

        @override
        Widget build(BuildContext context) {
                return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const[

                                        // Section : Général
                                        Text(
                                                "General",
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)
                                        ),
                                        SizedBox(height: 12),
                                        ListTile(
                                                leading: Icon(Icons.security),
                                                title: Text("Security"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        ),
                                        ListTile(
                                                leading: Icon(Icons.browse_gallery_outlined),
                                                title: Text("Reminders"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        ),
                                        ListTile(
                                                leading: Icon(Icons.collections_bookmark_rounded),
                                                title: Text("History"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        ),

                                        // Section : Aide & support
                                        SizedBox(height: 12),
                                        Text(
                                                "Help & Support",
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)
                                        ),
                                        SizedBox(height: 12),
                                        ListTile(
                                                leading: Icon(Icons.info_outline_rounded),
                                                title: Text("About"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        ),

                                        // Section : Confidentialité
                                        SizedBox(height: 12),
                                        Text(
                                                "Privacy",
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)
                                        ),
                                        SizedBox(height: 12),
                                        ListTile(
                                                leading: Icon(Icons.electrical_services_rounded),
                                                title: Text("Terms of Service"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        ),
                                        ListTile(
                                                leading: Icon(Icons.privacy_tip_rounded),
                                                title: Text("Privacy Policy"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        ),
                                        ListTile(
                                                leading: Icon(Icons.policy),
                                                title: Text("Security Policy"),
                                                trailing: Icon(Icons.arrow_forward_ios)
                                        )
                                ]
                        )
                );
        }
}