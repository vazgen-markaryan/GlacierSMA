/// Écran principal qui assemble l’en-tête, le corps et pilote le DashboardController,
/// et affiche un popup de perte de connexion avec le temps écoulé.

import '../utils/constants.dart';
import 'dashboard_body.dart';
import 'message_service.dart';
import 'package:flutter/material.dart';
import 'dashboard_header.dart';
import 'dashboard_controller.dart';
import '../debug/debug_log_manager.dart';
import '../../connection/managers/disconnection_manager.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/sensors/sensors_data.dart';

class DashboardScreen extends StatefulWidget {
        final FlutterSerialCommunication? plugin;
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;

        const DashboardScreen({
                super.key,
                required this.plugin,
                required this.isConnected,
                required this.connectedDevices
        });

        @override
        State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
        late final DashboardController controller;
        late final MessageService messageService;
        late bool isConnected;
        bool isDebugVisible = false;

        @override
        void initState() {
                super.initState();
                final debugManager = DebugLogManager();
                messageService = MessageService(
                        plugin: widget.plugin,
                        debugLogManager: debugManager,
                        isEmulator: false
                );
                isConnected = widget.isConnected;
                controller = DashboardController(
                        plugin: widget.plugin,
                        connectedDevices: widget.connectedDevices,
                        debugLogManager: debugManager,
                        messageService: messageService,
                        onConnectionLost: handleConnectionLost
                );
                controller.init(() => setState(() {
                                }
                        ));
        }

        Future<void> handleConnectionLost(Duration elapsed) async {
                if (!mounted) return;
                setState(() => isConnected = false);
                await showLostConnectionPopup(
                        context: context,
                        plugin: widget.plugin,
                        elapsedTime: elapsed
                );
        }

        @override
        void dispose() {
                controller.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return PopScope(
                        canPop: false,
                        onPopInvoked: (didPop) async {
                                if (!didPop) {
                                        final leave = await showDisconnectPopup(
                                                context: context,
                                                plugin: widget.plugin,
                                                requireConfirmation: true
                                        );
                                        if (leave) Navigator.of(context).pop();
                                }
                        },
                        child: Scaffold(
                                appBar: AppBar(
                                        automaticallyImplyLeading: false,
                                        backgroundColor: secondaryColor,
                                        title: DashboardHeader(
                                                isConnected: isConnected,
                                                connectedDevices: widget.connectedDevices,
                                                isDebugVisible: isDebugVisible,
                                                onToggleDebug: () => setState(() => isDebugVisible = !isDebugVisible),
                                                batteryVoltageNotifier: controller.batteryVoltage
                                        )
                                ),
                                body: ValueListenableBuilder<bool>(
                                        valueListenable: controller.isInitialLoading,
                                        builder: (ctx, loading, _) {
                                                if (loading) return const Center(child: CircularProgressIndicator());
                                                return DashboardBody(
                                                        isDebugVisible: isDebugVisible,
                                                        debugLogManager: controller.debugLogManager,
                                                        getSensors: getSensors,
                                                        sendCustomMessage: messageService.sendCustomMessage
                                                );
                                        }
                                )
                        )
                );
        }
}