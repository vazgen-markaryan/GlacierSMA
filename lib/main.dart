import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

void main() {
        runApp(const MyApp());
}

class MyApp extends StatefulWidget {
        const MyApp({super.key});

        @override
        State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
        final flutterSerialCommunicationPlugin = FlutterSerialCommunication();
        bool isConnected = false;
        List<DeviceInfo> connectedDevices = [];
        EventChannel? messageChannel;

        String sentMessageStatus = '';
        String buffer = '';
        String receivedMessage = '';
        bool isCapturing = false;

        @override
        void initState() {
                super.initState();
                flutterSerialCommunicationPlugin
                        .getDeviceConnectionListener()
                        .receiveBroadcastStream()
                        .listen((event) {
                                        setState(() => isConnected = event);
                                }
                        );
                messageChannel = flutterSerialCommunicationPlugin.getSerialMessageListener();
        }

        Future<void> getAllConnectedDevices() async {
                List<DeviceInfo> newConnectedDevices =
                        await flutterSerialCommunicationPlugin.getAvailableDevices();
                setState(() => connectedDevices = newConnectedDevices);
        }

        Future<void> connect(DeviceInfo deviceInfo) async {
                bool success =
                        await flutterSerialCommunicationPlugin.connect(deviceInfo, 115200);
                debugPrint("Connection success: $success");
                sendMessage("Android"); // Envoi d'un message de test après la connexion
        }

        Future<void> disconnect() async {
                await flutterSerialCommunicationPlugin.disconnect();
        }

        Future<void> sendMessage(String message) async {
                if (!isConnected) {
                        setState(() => sentMessageStatus = "Erreur : Pas de connexion active.");
                        return;
                }

                Uint8List data = convertStringToUint8List(message);
                try {
                        bool isMessageSent = await flutterSerialCommunicationPlugin.write(data);
                        setState(() => sentMessageStatus = "Message : \"$message\" statut d'envoi : ${isMessageSent.toString().toUpperCase()}");

                        // Effacer le statut après 3 secondes
                        Future.delayed(const Duration(seconds: 3), () {
                                        setState(() => sentMessageStatus = '');
                                }
                        );
                }
                catch (e) {
                        setState(() => sentMessageStatus = "Erreur lors de l'envoi du message : $e");
                }
        }

        Uint8List convertStringToUint8List(String input) {
                return Uint8List.fromList(input.codeUnits);
        }

        void readMessage() {
                messageChannel?.receiveBroadcastStream().listen((event) {
                                if (event is Uint8List) {
                                        final chunk = String.fromCharCodes(event);
                                        buffer += chunk;

                                        if (buffer.contains("<phone_start>")) {
                                                isCapturing = true;
                                                buffer = "";
                                        }
                                        if (isCapturing && buffer.contains("<phone_end>")) {
                                                isCapturing = false;
                                                final rawData = buffer.replaceAll("<phone_start>", "").replaceAll("<phone_end>", "").trim();
                                                List<String> lines = rawData.split('\n').map((e) => e.trim()).toList();
                                                if (lines.isNotEmpty) {
                                                        if (lines[0] == "<data>" && lines.length >= 3) {
                                                                final headers = lines[1].split(',');
                                                                final values = lines[2].split(',');
                                                                final dataMap = Map.fromIterables(headers, values);
                                                                setState(() => receivedMessage = "SENSORS DATA:\n$dataMap");
                                                        }
                                                        else if (lines[0] == "<status>" && lines.length >= 3) {
                                                                final headers = lines[1].split(',');
                                                                final values = lines[2].split(',');
                                                                final statusMap = Map.fromIterables(headers, values);
                                                                setState(() => receivedMessage = "SENSORS STATUS:\n$statusMap");
                                                        }
                                                }
                                                buffer = "";
                                        }
                                }
                        }
                );
        }

        @override
        Widget build(BuildContext context) {
                return MaterialApp(
                        home: Scaffold(
                                appBar: AppBar(title: const Text('Glacier SMA')),
                                body: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                        buildConnectionStatus(),
                                                        buildDeviceList(),
                                                        buildActionButtons(),
                                                        buildMessageSection(),
                                                        buildSentMessageStatus()
                                                ]
                                        )
                                )
                        )
                );
        }

        Widget buildConnectionStatus() {
                return Card(
                        child: ListTile(
                                leading: Icon(isConnected ? Icons.usb : Icons.usb_off, color: isConnected ? Colors.green : Colors.red),
                                title: Text(isConnected ? "Connected" : "Not Connected")
                        )
                );
        }

        Widget buildDeviceList() {
                return Column(
                        children: connectedDevices.map((device) {
                                        return Card(
                                                child: ListTile(
                                                        title: Text(device.productName),
                                                        trailing: ElevatedButton(
                                                                onPressed: () => connect(device),
                                                                child: const Text("Connect")
                                                        )
                                                )
                                        );
                                }
                        ).toList()
                );
        }

        Widget buildActionButtons() {
                return Column(
                        children: [
                                ElevatedButton(
                                        onPressed: getAllConnectedDevices,
                                        child: const Text("Get All Connected Devices")
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                        onPressed: isConnected ? disconnect : null,
                                        child: const Text("Disconnect")
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                        onPressed: isConnected ? () => sendMessage("Test Button") : null,
                                        child: const Text("Send Message")
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                        onPressed: isConnected ? readMessage : null,
                                        child: const Text("Read Message")
                                )
                        ]
                );
        }

        Widget buildMessageSection() {
                return Card(
                        child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                const Text("Received Message:", style: TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                Text(receivedMessage, style: const TextStyle(fontSize: 16))
                                        ]
                                )
                        )
                );
        }

        Widget buildSentMessageStatus() {
                return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                const SizedBox(height: 16.0),
                                Text(sentMessageStatus, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                        ]);
        }
}