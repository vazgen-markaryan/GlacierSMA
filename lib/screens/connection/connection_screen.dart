import 'language_popup.dart';
import 'connection_widgets.dart';
import 'connection_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

/// Écran de connexion : permet de se connecter à un appareil via Bluetooth ou USB
/// Affiche un Popup de sélection de langue et un écran de connexion
/// Gère la connexion et la déconnexion
/// Gère l'affichage des appareils connectés
/// Gère l'affichage des instructions de connexion
class ConnectionScreen extends StatefulWidget {
        const ConnectionScreen({super.key});

        @override
        State<ConnectionScreen> createState() => ConnectionScreenState();
}

class ConnectionScreenState extends State<ConnectionScreen> {
        // Plugin pour la communication série
        final plugin = FlutterSerialCommunication();

        // Liste des appareils détectés via USB
        List<DeviceInfo> connectedDevices = [];

        // État du popup langue
        bool langPopupVisible = false;
        OverlayEntry? langOverlay;

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                centerTitle: true,
                                automaticallyImplyLeading: false,
                                title: Text(tr("connection.appTitle")),
                                actions: [
                                        // L’icône drapeau à droite
                                        Builder(builder: (context) {
                                                        return GestureDetector(
                                                                onTap: () => toggleLangPopup(context),
                                                                child: Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 32),
                                                                        child: SvgPicture.asset(
                                                                                'assets/icons/${context.locale.languageCode}.svg',
                                                                                width: 32,
                                                                                height: 32
                                                                        )
                                                                )
                                                        );
                                                }
                                        )
                                ]
                        ),
                        body: LayoutBuilder(
                                builder: (context, constraints) {
                                        final isHorizontal = constraints.maxWidth > 700;
                                        return Container(
                                                padding: const EdgeInsets.all(defaultPadding),
                                                color: backgroundColor,
                                                child: isHorizontal
                                                        // Mode paysage : Bluetooth / câble côte à côte
                                                        ? Row(
                                                                children: [
                                                                        Expanded(child: buildBluetoothSection(context)),
                                                                        const SizedBox(width: defaultPadding),
                                                                        Expanded(child: buildCableSection(context, onCable))
                                                                ]
                                                        )
                                                        // Mode portrait : Bluetooth, instructions, câble
                                                        : Column(
                                                                children: [
                                                                        Expanded(child: buildBluetoothSection(context)),
                                                                        const SizedBox(height: defaultPadding * 0.75),
                                                                        buildArrowInstruction(),
                                                                        const SizedBox(height: defaultPadding * 0.75),
                                                                        Expanded(child: buildCableSection(context, onCable))
                                                                ]
                                                        )
                                        );
                                }
                        )
                );
        }

        /// Launch la détection et la sélection d’un device câble
        Future<void> onCable() async {
                // 1) Récupère la liste des devices USB
                await getAllCableConnectedDevices(
                        plugin,
                        (devs) => setState(() => connectedDevices = devs)
                );
                // 2) Ouvre le dialog de sélection
                await showDeviceSelectionDialog(context, connectedDevices, plugin);
                // 3) Vide la liste après fermeture
                setState(() => connectedDevices.clear());
        }

        /// Ouvre / ferme le popup de sélection de langue
        void toggleLangPopup(BuildContext targetCtx) {
                if (langPopupVisible) {
                        // Si déjà visible, on ferme
                        langOverlay?.remove();
                        langPopupVisible = false;
                        return;
                }
                langPopupVisible = true;

                // On récupère la position et la taille de l’icône drapeau
                final render = targetCtx.findRenderObject();
                if (render is! RenderBox) return;
                final box = render;
                final pos = box.localToGlobal(Offset.zero);
                final iconSize = box.size.width;
                final screen = MediaQuery.of(context).size;

                langOverlay = OverlayEntry(
                        builder: (_) {
                                // Calcul pour que le popup s’aligne à gauche du SVG
                                final right = screen.width - pos.dx - iconSize;
                                final top = pos.dy + box.size.height + 5.0; // 5px d’écart sous le drapeau

                                return GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                                // Clique hors du popup → ferme
                                                langOverlay?.remove();
                                                langPopupVisible = false;
                                        },
                                        child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                        Positioned(
                                                                right: right,
                                                                top: top,
                                                                child: LanguagePopup(
                                                                        // Position de la flèche : moitié de la largeur du SVG
                                                                        iconCenterOffset: iconSize - 25,
                                                                        onSelect: (loc) {
                                                                                // Lorsqu’on choisit une langue
                                                                                context.setLocale(loc);
                                                                                langOverlay?.remove();
                                                                                langPopupVisible = false;
                                                                        }
                                                                )
                                                        )
                                                ]
                                        )
                                );
                        }
                );

                Overlay.of(context).insert(langOverlay!);
        }
}