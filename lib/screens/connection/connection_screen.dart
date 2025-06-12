import 'language_popup.dart';
import 'connection_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

class ConnectionScreen extends StatefulWidget {
        const ConnectionScreen({super.key});

        @override
        State<ConnectionScreen> createState() => ConnectionScreenState();
}

class ConnectionScreenState extends State<ConnectionScreen> {
        final plugin = FlutterSerialCommunication();

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
                                        Builder(builder: 
                                                (context) {
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
                                        return Container(
                                                padding: const EdgeInsets.all(16),
                                                color: backgroundColor,
                                                child: Column(
                                                        children: [
                                                                Expanded(child: buildBluetoothSection(context)),
                                                                const SizedBox(height: 12),
                                                                buildArrowInstruction(),
                                                                const SizedBox(height: 12),
                                                                Expanded(child: buildCableSection(context))
                                                        ]
                                                )
                                        );
                                }
                        )
                );
        }

        Widget buildBluetoothSection(BuildContext context) {
                return GestureDetector(
                        onTap: () => scanBleDevices(context),
                        child: Card(
                                color: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Center(
                                        child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                        Icon(Icons.bluetooth, size: 64, color: Colors.white),
                                                        SizedBox(height: 8),
                                                        Text(tr("connection.bluetooth_connection"),
                                                                style: TextStyle(fontSize: 18, color: Colors.white))
                                                ]
                                        )
                                )
                        )
                );
        }

        Widget buildCableSection(BuildContext context) {
                return GestureDetector(
                        onTap: () => scanUsbDevices(context, plugin),
                        child: Card(
                                color: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Center(
                                        child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                        Icon(Icons.usb_rounded, size: 64, color: Colors.white),
                                                        SizedBox(height: 8),
                                                        Text(tr("connection.cable_connection"),
                                                                style: TextStyle(fontSize: 18, color: Colors.white))
                                                ]
                                        )
                                )
                        )
                );
        }

        Widget buildArrowInstruction() {
                return Row(
                        children: [
                                Expanded(child: Divider(color: Colors.white24)),
                                Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Column(
                                                children: [
                                                        Icon(Icons.keyboard_arrow_up, color: Colors.white54),
                                                        Text(tr("connection.arrow_instruction"),
                                                                style: TextStyle(color: Colors.white54)),
                                                        Icon(Icons.keyboard_arrow_down, color: Colors.white54)
                                                ]
                                        )
                                ),
                                Expanded(child: Divider(color: Colors.white24))
                        ]
                );
        }

        void toggleLangPopup(BuildContext targetContext) {
                if (langPopupVisible) {
                        langOverlay?.remove();
                        langPopupVisible = false;
                        return;
                }
                langPopupVisible = true;

                final render = targetContext.findRenderObject();
                if (render is! RenderBox) return;
                final box = render;
                final position = box.localToGlobal(Offset.zero);
                final iconSize = box.size.width;
                final screen = MediaQuery.of(context).size;

                langOverlay = OverlayEntry(
                        builder: (_) {
                                final right = screen.width - position.dx - iconSize;
                                final top = position.dy + box.size.height + 5.0;

                                return GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
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
                                                                        iconCenterOffset: iconSize - 25,
                                                                        onSelect: (locale) {
                                                                                context.setLocale(locale);
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