import 'package:easy_localization/easy_localization.dart';

import 'bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'dashboard/dashboard_utils.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import '../connection/disconnection_manager.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/dashboard/dashboard_header.dart';

/// Écran principal qui gère l'affichage des onglets et la navigation
class Home_Screen extends StatefulWidget {
        final FlutterSerialCommunication? plugin;
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;

        const Home_Screen({
                Key? key,
                required this.plugin,
                required this.isConnected,
                required this.connectedDevices
        }) : super(key: key);

        @override
        State<Home_Screen> createState() => Home_ScreenState();
}

class Home_ScreenState extends State<Home_Screen> with DashboardUtils {
        @override
        void initState() {
                super.initState();
                initDashboard(widget);
        }

        @override
        Widget build(BuildContext context) {
                return PopScope(
                        canPop: false,
                        onPopInvoked: handleSystemPop,
                        child: Scaffold(
                                backgroundColor: backgroundColor,
                                appBar: AppBar(
                                        automaticallyImplyLeading: false,
                                        backgroundColor: secondaryColor,
                                        title: DashboardHeader(
                                                isConnected: isConnected,
                                                connectedDevices: widget.connectedDevices,
                                                batteryVoltageNotifier: controller.batteryVoltage,
                                                firmwareNotifier: controller.firmwareNotifier,
                                                onRename: showRenameDialog
                                        ),
                                        actions: [
                                                IconButton(
                                                        icon: const Icon(Icons.logout),
                                                        onPressed: () {
                                                                final testState = testScreenKey.currentState;
                                                                if (testState != null && testState.isTesting) {
                                                                        // Si un test est en cours, on bloque et on affiche un avertissement
                                                                        showDialog(
                                                                                context: context,
                                                                                barrierDismissible: false,
                                                                                builder: (_) => CustomPopup(
                                                                                        title: tr("home.dashboard.test_enabled"),
                                                                                        content: Text(tr("home.dashboard.stop_test_before_switching")),
                                                                                        actions: [
                                                                                                TextButton(
                                                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                                                        child: const Text('OK')
                                                                                                )
                                                                                        ]
                                                                                )
                                                                        );
                                                                }
                                                                else {
                                                                        // Sinon on fait ce qu’on faisait avant
                                                                        showDisconnectPopup(
                                                                                context: context,
                                                                                plugin: widget.plugin,
                                                                                requireConfirmation: true
                                                                        );
                                                                }
                                                        }
                                                )
                                        ]
                                ),
                                body: pages[selectedIndex],
                                bottomNavigationBar: BottomNavBar(
                                        selectedIndex: selectedIndex,
                                        onItemTapped: onNavItemTapped
                                )
                        )
                );
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }
}