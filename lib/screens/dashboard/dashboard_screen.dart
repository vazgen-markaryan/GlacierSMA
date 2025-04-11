import 'dart:async';
import 'package:flutter/rendering.dart';

import '../../constantes.dart';
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

        // DEBUG MOD
        DateTime? lastLogTime; // Variable pour limiter la fréquence des logs
        bool isDebugVisible = false; // État pour afficher ou masquer les logs
        List<String> debugLogs = []; // Liste pour stocker les logs de débogage
        List<String> tempLogBuffer = []; // Buffer temporaire pour collecter les logs
        bool isUserScrolling = false; // Indique si l'utilisateur fait défiler manuellement
        Timer? scrollInactivityTimer; // Timer pour surveiller l'inactivité de défilement
        final ScrollController _scrollController = ScrollController();

        @override
        void initState() {
                super.initState();
                isConnected = widget.isConnected;

                // Initialisation de messageChannel pour écouter les messages Serial
                messageChannel = widget.flutterSerialCommunicationPlugin?.getSerialMessageListener();

                // Indiquer à Arduino qu'il est connecté
                widget.flutterSerialCommunicationPlugin?.setDTR(true);

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

                // Timer pour écrire les chunks toutes les 3 secondes
                Timer.periodic(const Duration(seconds: 3), (timer) {
                                if (tempLogBuffer.isNotEmpty) {
                                        setState(() {
                                                        debugLogs.add("-----START LOG CHUNK-----\n");
                                                        debugLogs.addAll(tempLogBuffer);
                                                        debugLogs.add("\n-----END LOG CHUNK-----");
                                                        tempLogBuffer.clear(); // Vider le buffer temporaire
                                                }
                                        );

                                        // Auto-scroll si l'utilisateur ne fait pas défiler
                                        if (!isUserScrolling && _scrollController.hasClients) {
                                                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                        }
                                }
                        }
                );

                // Écoute des interactions de défilement
                _scrollController.addListener(() {
                                if (_scrollController.position.userScrollDirection != ScrollDirection.idle) {
                                        isUserScrolling = true;

                                        // Réinitialiser le timer d'inactivité
                                        scrollInactivityTimer?.cancel();
                                        scrollInactivityTimer = Timer(const Duration(seconds: 5), () {
                                                        setState(() {
                                                                        isUserScrolling = false;
                                                                }
                                                        );

                                                        // Auto-scroll si l'utilisateur est inactif
                                                        if (_scrollController.hasClients) {
                                                                _scrollController.animateTo(
                                                                        _scrollController.position.maxScrollExtent,
                                                                        duration: const Duration(milliseconds: 300),
                                                                        curve: Curves.easeOut
                                                                );
                                                        }
                                                }
                                        );
                                }
                        }
                );
        }

        void addDebugLog(String log) {
                tempLogBuffer.add(log); // Ajouter le log au buffer temporaire
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
                                        "Connexion perdue. Vérifiez le câble ou la switch hardware du Debug Mod",
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

        // Méthode pour envoyer un message avec journalisation
        Future<bool> sendMessage(String message) async {
                Uint8List data = convertStringToUint8List(message);
                try {
                        bool isMessageSent = await widget.flutterSerialCommunicationPlugin?.write(data) ?? false;

                        // Ajouter un log pour l'envoi
                        addDebugLog("\nMessage envoyé : $message");

                        return isMessageSent;
                }
                catch (e) {
                        addDebugLog("Erreur lors de l'envoi : $e");
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                                buildConnectionStatus(),
                                                buildDebugToggleButton() // Bouton toggle
                                        ]
                                )
                        ),
                        body: SafeArea(
                                child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                        if (isDebugVisible) buildDebugMenu(), // Affichage conditionnel des logs
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
                                                        )
                                                ]
                                        )
                                )
                        )
                );
        }

        // Méthode pour lire les messages avec journalisation
        void readMessage() {
                sendMessage(communicationMessageAndroid);
                messageChannel?.receiveBroadcastStream().listen(
                        (event) {
                                if (event is Uint8List) {
                                        final chunk = String.fromCharCodes(event);
                                        buffer += chunk;

                                        if (buffer.contains(communicationMessagePhoneStart)) {
                                                addDebugLog("\nBuffer contient Header");
                                                isCapturing = true;
                                                buffer = "";
                                        }

                                        if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                                isCapturing = false;
                                                final rawData = buffer
                                                        .replaceAll(communicationMessagePhoneStart, "")
                                                        .replaceAll(communicationMessagePhoneEnd, "")
                                                        .trim();

                                                // Ajouter un log pour la réception
                                                addDebugLog("\nMessage reçu : $rawData");

                                                updateSensorsData(rawData);
                                                buffer = "";
                                        }
                                }
                        }
                );
        }

        Widget buildDebugMenu() {
                return Card(
                        child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                const Text("Logs de débogage :", style: TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                        height: 200,
                                                        child: ListView.builder(
                                                                controller: _scrollController,
                                                                itemCount: debugLogs.length,
                                                                itemBuilder: (context, index) {
                                                                        return Text(debugLogs[index], style: const TextStyle(fontSize: 14));
                                                                }
                                                        )
                                                )
                                        ]
                                )
                        )
                );
        }

        void updateSensorsData(String rawData) {
                String statusMessage = '';
                String dataMessage = '';

                if (rawData.contains(communicationMessageStatus)) {
                        // Extraire les données de statut
                        final headers = rawData.split('\n')[1].split(',');
                        final values = rawData.split('\n')[2].split(',');

                        // Mettre à jour les statuts des capteurs
                        for (int i = 0; i < headers.length; i++) {
                                final sensorName = headers[i].trim();
                                final status = int.tryParse(values[i].trim()) ?? 0;

                                // Mettre à jour les capteurs internes
                                for (var sensor in internalSensors) {
                                        if (sensor.header?.toLowerCase() == sensorName.toLowerCase()) {
                                                sensor.powerStatus = status;
                                        }
                                }

                                // Mettre à jour les capteurs du vent
                                for (var sensor in windSensors) {
                                        if (sensor.header?.toLowerCase() == sensorName.toLowerCase()) {
                                                sensor.powerStatus = status;
                                        }
                                }

                                // Mettre à jour les capteurs Stevenson
                                for (var sensor in stevensonSensors) {
                                        if (sensor.header?.toLowerCase() == sensorName.toLowerCase()) {
                                                sensor.powerStatus = status;
                                        }
                                }
                        }

                        // Construire le message de statut
                        statusMessage = "SENSORS STATUS:\n${Map.fromIterables(headers, values)}";
                }

                if (rawData.contains(communicationMessageData)) {
                        // Extraire les données des capteurs
                        final headers = rawData.split('\n')[1].split(',');
                        final values = rawData.split('\n')[2].split(',');

                        // Construire le message de données
                        dataMessage = "SENSORS DATA:\n${Map.fromIterables(headers, values)}";
                }

                // Mettre à jour le message reçu avec les deux types d'informations
                setState(() {
                                receivedMessage = "$statusMessage\n\n$dataMessage";
                        }
                );
        }

        Widget buildDebugToggleButton() {
                return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                                onTap: () {
                                        setState(() {
                                                        isDebugVisible = !isDebugVisible;
                                                }
                                        );
                                },
                                child: Row(
                                        children: [
                                                const Text("Debug", style: TextStyle(fontSize: 16, color: Colors.white)),
                                                const SizedBox(width: 8),
                                                Container(
                                                        width: 60,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                                color: isDebugVisible ? Colors.green : Colors.grey,
                                                                borderRadius: BorderRadius.circular(15)
                                                        ),
                                                        child: AnimatedAlign(
                                                                duration: const Duration(milliseconds: 200),
                                                                alignment: isDebugVisible ? Alignment.centerRight : Alignment.centerLeft,
                                                                child: Container(
                                                                        width: 25,
                                                                        height: 25,
                                                                        decoration: const BoxDecoration(
                                                                                color: Colors.white,
                                                                                shape: BoxShape.circle
                                                                        )
                                                                )
                                                        )
                                                )
                                        ]
                                )
                        )
                );
        }
}