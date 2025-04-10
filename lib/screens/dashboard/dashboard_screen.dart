import 'dart:async';
import '../../constants.dart';
import 'components/sensors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../sensors_data/sensors_data.dart';
import '../connection/connection_screen.dart';
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
        Timer? connectionCheckTimer;
        EventChannel? messageChannel;
        String buffer = '';
        String receivedMessage = '';
        bool isCapturing = false;

        @override
        void initState() {
                super.initState();
                isConnected = widget.isConnected;

                // Initialisation de messageChannel pour écouter les messages Serial
                messageChannel = widget.flutterSerialCommunicationPlugin?.getSerialMessageListener();

                // Appeler readMessage pour écouter les messages
                readMessage();

                // Vérification périodique de l'état de connexion
                connectionCheckTimer = Timer.periodic(const Duration(seconds: 2),
                        (timer) async {
                                //Envoi du message <android> pour PING Arduino et s'assurer que la connexion est toujours active
                                bool isMessageSent = await sendMessage(communicationMessageAndroid);
                                if (!isMessageSent && isConnected) {
                                        setState(() => isConnected = false);
                                        showDisconnectionDialog();
                                }
                        }
                );
        }

        @override
        void dispose() {
                connectionCheckTimer?.cancel();
                super.dispose();
        }

        // Methode pour afficher la boîte de dialogue de déconnexion si la connexion est perdue
        Future<void> showDisconnectionDialog() async {
                await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text(
                                        "Déconnexion",
                                        style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                                content: const Text(
                                        "Connexion perdue. Vérifiez le câble.",
                                        style: TextStyle(color: Colors.white70, fontSize: 16)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () {
                                                        Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                        "OK",
                                                        style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                                                )
                                        )
                                ]
                        )
                );

                // Déconnecter après la boîte de dialogue
                await disconnect();
        }

        // Methode qui force la déconnexion
        Future<void> disconnect() async {
                await widget.flutterSerialCommunicationPlugin?.disconnect();
                setState(() {
                                isConnected = false;
                        }
                );

                // Redirection vers l'écran de connexion
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConnectionScreen()));
        }

        // Methode pour envoyer un message à Arduino
        Future<bool> sendMessage(String message) async {
                Uint8List data = convertStringToUint8List(message);
                try {
                        bool isMessageSent = await widget.flutterSerialCommunicationPlugin?.write(data) ?? false;
                        return isMessageSent;
                }
                catch (e) {
                        return false;
                }
        }

        // Methode pour convertir une chaîne de caractères en Uint8List pour Arduino
        Uint8List convertStringToUint8List(String input) {
                return Uint8List.fromList(input.codeUnits);
        }

        // Methode pour afficher la boîte de dialogue de déconnexion si l'utilisateur veut quitter
        Future<void> showDisconnectConfirmationDialog(BuildContext context) async {
                final shouldDisconnect = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text(
                                        "Déconnexion",
                                        style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                                content: const Text(
                                        "Voulez-vous vraiment vous déconnecter ?",
                                        style: TextStyle(color: Colors.white70, fontSize: 16)
                                ),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text(
                                                        "Non",
                                                        style: TextStyle(color: Colors.white, fontSize: 16)
                                                )
                                        ),
                                        TextButton(
                                                onPressed: () async {
                                                        await widget.flutterSerialCommunicationPlugin?.disconnect();
                                                        Navigator.of(context).pop(true);
                                                },
                                                child: const Text(
                                                        "Oui",
                                                        style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)
                                                )
                                        )
                                ]
                        )
                ) ?? false;

                // Si l'utilisateur a confirmé la déconnexion affiche un message de succès
                if (shouldDisconnect) {
                        ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                        content: Text("Déconnecté avec succès.")
                                )
                        );

                        // Redirection vers l'écran de connexion
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConnectionScreen()));
                }
        }

        // Widget qui affiche l'état de la connexion en haut de l'écran
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

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                automaticallyImplyLeading: false,
                                backgroundColor: secondaryColor,
                                title: Row(
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
                                ),
                                actions: [
                                        IconButton(
                                                icon: const Icon(Icons.logout, color: Colors.white),
                                                onPressed: () => showDisconnectConfirmationDialog(context)
                                        )
                                ]
                        ),
                        body: SafeArea(
                                child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                        SizedBox(height: defaultPadding),
                                                        MySensors(
                                                                title: "Les Capteurs Internes",
                                                                sensors: internalSensors
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        MySensors(
                                                                title: "Les Capteurs du Vent",
                                                                sensors: windSensors
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        MySensors(
                                                                title: "Les Capteurs Stevenson",
                                                                sensors: stevensonSensors
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        Card(
                                                                child: Padding(
                                                                        padding: const EdgeInsets.all(12.0),
                                                                        child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                        const Text("Reception du data:", style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                        const SizedBox(height: 8),
                                                                                        Text(receivedMessage, style: const TextStyle(fontSize: 16))
                                                                                ]
                                                                        )
                                                                )
                                                        )
                                                ]
                                        )
                                )
                        )
                );
        }

        void readMessage() {
                //Envoi du message <android> pour initier la communication avec Arduino
                sendMessage(communicationMessageAndroid);

                messageChannel?.receiveBroadcastStream().listen(
                        (event) {
                                if (event is Uint8List) {
                                        final chunk = String.fromCharCodes(event);
                                        buffer += chunk;
                                        if (buffer.contains(communicationMessagePhoneStart)) {
                                                isCapturing = true;
                                                buffer = "";
                                        }
                                        if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                                isCapturing = false;
                                                final rawData = buffer.replaceAll(communicationMessagePhoneStart, "").replaceAll(communicationMessagePhoneEnd, "").trim();
                                                List<String> lines = rawData.split('\n').map((e) => e.trim()).toList();
                                                if (lines.isNotEmpty) {
                                                        if (lines[0] == communicationMessageData && lines.length >= 3) {
                                                                final headers = lines[1].split(',');
                                                                final values = lines[2].split(',');
                                                                final dataMap = Map.fromIterables(headers, values);
                                                                setState(() => receivedMessage = "SENSORS DATA:\n$dataMap");
                                                        }
                                                        else if (lines[0] == communicationMessageStatus && lines.length >= 3) {
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

        Widget buildMessageSection() {
                return Card(
                        child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                const Text("Reception du data:", style: TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                Text(receivedMessage, style: const TextStyle(fontSize: 16))
                                        ]
                                )
                        )
                );
        }
}