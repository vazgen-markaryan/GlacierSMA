import 'dart:async';
import '../../constants.dart';
import 'sensors/sensors_data.dart';
import 'functions/data_reader.dart';
import 'sensors/sensors_group.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'debug_menu/debug_toggle.dart';
import 'utils/disconnection_manager.dart';
import 'debug_menu/debug_data_parser.dart';
import 'debug_menu/debug_log_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';

class DashboardScreen extends StatefulWidget {
        final FlutterSerialCommunication? flutterSerialCommunicationPlugin;
        final bool isConnected;
        final List<DeviceInfo> connectedDevices;

        const DashboardScreen({
                super.key,
                required this.flutterSerialCommunicationPlugin,
                required this.isConnected,
                required this.connectedDevices
        });

        @override
        State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
        late bool isConnected;
        late final ValueNotifier<bool> isInitialLoading;
        Timer? connectionCheckTimer;
        EventChannel? messageChannel;

        bool isDebugVisible = false;
        late bool isEmulator;
        final DebugLogManager debugLogManager = DebugLogManager();

        late int stevensonTemp;
        late int stevensonHum;
        late int stevensonPress;

        @override
        void initState() {
                super.initState();
                isConnected = widget.isConnected;
                isInitialLoading = ValueNotifier(true);
                isEmulator = false;

                // Vérifie si on est sur un émulateur
                DeviceInfoPlugin().androidInfo.then(
                        (info) {
                                isEmulator = !info.isPhysicalDevice;

                                if (!isEmulator) {
                                        // Initialiser les éléments réels seulement sur un vrai appareil
                                        messageChannel = widget.flutterSerialCommunicationPlugin?.getSerialMessageListener();
                                        widget.flutterSerialCommunicationPlugin?.setDTR(true);

                                        readMessage(
                                                messageChannel: messageChannel,
                                                sendMessage: sendMessage,
                                                debugLogManager: debugLogManager,
                                                getSensors: getSensors,
                                                setTemp: (v) => stevensonTemp = v,
                                                setHum: (v) => stevensonHum = v,
                                                setPres: (v) => stevensonPress = v,
                                                onDataReceived: () {
                                                        final hasData = [
                                                                ...getSensors(SensorType.internal),
                                                                ...getSensors(SensorType.modbus),
                                                                ...getSensors(SensorType.stevenson),
                                                                ...getSensors(SensorType.stevensonStatus)
                                                        ].any((sensor) => sensor.powerStatus != null);
                                                        if (hasData) isInitialLoading.value = false;
                                                }
                                        );

                                        // Timer de ping toutes les 2s
                                        connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
                                                        bool isMessageSent = await sendMessage(communicationMessageAndroid);
                                                        if (!isMessageSent && isConnected) {
                                                                setState(() => isConnected = false);
                                                                showDisconnectionDialog(context, () => handleDisconnection(context, widget.flutterSerialCommunicationPlugin));
                                                        }
                                                }
                                        );
                                }
                                else {
                                        // Simule un délai de chargement pour l'UI
                                        Future.delayed(const Duration(seconds: 1), () {
                                                        isInitialLoading.value = false;
                                                }
                                        );
                                }
                        }
                );
        }

        @override
        void dispose() {
                connectionCheckTimer?.cancel();
                isInitialLoading.dispose();
                super.dispose();
        }

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                automaticallyImplyLeading: false,
                                backgroundColor: secondaryColor,
                                title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                                buildConnectionStatus(),
                                                DebugToggleButton(isDebugVisible: isDebugVisible, onToggle: toggleDebugMode)
                                        ]
                                )
                        ),
                        body: SafeArea(
                                child: ValueListenableBuilder<bool>(
                                        valueListenable: isInitialLoading,
                                        builder: (context, loading, _) {
                                                if (loading) return const Center(child: CircularProgressIndicator());

                                                return SingleChildScrollView(
                                                        padding: const EdgeInsets.all(defaultPadding),
                                                        child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                        if (isDebugVisible) DebugData(debugLogManager: debugLogManager),
                                                                        const SizedBox(height: defaultPadding),
                                                                        SensorsGroup(
                                                                                title: "Les Capteurs Internes",
                                                                                sensors: getSensors(SensorType.internal),
                                                                                isDebugMode: isDebugVisible
                                                                        ),
                                                                        const SizedBox(height: defaultPadding),
                                                                        SensorsGroup(
                                                                                title: "Les Capteurs ModBus",
                                                                                sensors: getSensors(SensorType.modbus),
                                                                                isDebugMode: isDebugVisible
                                                                        ),
                                                                        const SizedBox(height: defaultPadding),
                                                                        SensorsGroup(
                                                                                title: "Les Capteurs Stevenson",
                                                                                sensors: getSensors(SensorType.stevensonStatus).first.powerStatus == 2
                                                                                        ? getSensors(SensorType.stevensonStatus)
                                                                                        : getSensors(SensorType.stevenson),
                                                                                isDebugMode: isDebugVisible
                                                                        ),
                                                                        const SizedBox(height: defaultPadding),
                                                                        Center(
                                                                                child: ElevatedButton(
                                                                                        onPressed: () async {
                                                                                                final success = await sendCustomMessage("<active>", Uint8List.fromList([0xff, 0xff]));
                                                                                                // final success = await sendMessage("<active>");

                                                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                                                        SnackBar(
                                                                                                                content: Text(
                                                                                                                        success
                                                                                                                                ? "Message envoyé"
                                                                                                                                : "Échec de l'envoi du message."
                                                                                                                ),
                                                                                                                backgroundColor: success ? Colors.green : Colors.red
                                                                                                        )
                                                                                                );
                                                                                        },
                                                                                        style: ElevatedButton.styleFrom(
                                                                                                backgroundColor: Colors.blue,
                                                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                                                                                        ),
                                                                                        child: const Text(
                                                                                                "Envoyer Message",
                                                                                                style: TextStyle(fontSize: 16)
                                                                                        )
                                                                                )
                                                                        )
                                                                ]
                                                        )
                                                );
                                        }
                                )
                        )
                );
        }

        Widget buildConnectionStatus() {
                return Row(
                        children: [
                                Icon(isConnected ? Icons.usb : Icons.usb_off, color: isConnected ? Colors.green : Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                        isConnected
                                                ? (widget.connectedDevices.isNotEmpty ? widget.connectedDevices.first.productName : "Appareil inconnu")
                                                : "Non connecté",
                                        style: const TextStyle(fontSize: 16)
                                )
                        ]
                );
        }

        void toggleDebugMode() {
                setState(() {
                                isDebugVisible = !isDebugVisible;
                        }
                );
        }

        Future<bool> sendMessage(String message) async {
                if (isEmulator) return false; // Pas d’envoi en mode UI-only

                final Uint8List data = Uint8List.fromList(message.codeUnits);

                try {
                        final result = await widget.flutterSerialCommunicationPlugin!.write(data);
                        debugLogManager.setLogChunk(0, "Message envoyé : $message");
                        debugLogManager.updateLogs();
                        return result;
                }
                catch (error) {
                        debugLogManager.setLogChunk(0, "Erreur lors de l'envoi : $error");
                        debugLogManager.updateLogs();
                        return false;
                }
        }

        Future<bool> sendCustomMessage(String prefix, Uint8List message) async {

                // Ajout du préfixe et du suffixe au message
                final Uint8List data = Uint8List.fromList([
                                ...prefix.codeUnits,
                                ...message
                        ]);

                try {
                        final result = await widget.flutterSerialCommunicationPlugin!.write(data);

                        debugLogManager.setLogChunk(0, "Message envoyé : ${data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}");

                        debugLogManager.updateLogs();
                        return result;
                }
                catch (error) {
                        debugLogManager.setLogChunk(0, "Erreur lors de l'envoi : $error");
                        debugLogManager.updateLogs();
                        return false;
                }
        }
}