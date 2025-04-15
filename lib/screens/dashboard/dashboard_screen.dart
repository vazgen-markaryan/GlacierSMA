import 'dart:async';
import 'dart:math';
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
        bool isCapturing = false;

        // DEBUG MOD
        bool isDebugVisible = false; // État pour afficher ou masquer les logs
        List<String> debugLogs = []; // Liste pour stocker les logs de débogage
        List<String> tempLogBuffer = ["", "", ""]; // Buffer temporaire pour collecter les logs

        // Variables globales pour BME de Stevenson
        late int stevensonTemp;
        late int stevensonHum;
        late int stevensonPress;

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
                        tempLogBuffer[0] = "\nMessage envoyé : $message\n";
                        updateLogs();

                        return isMessageSent;
                }
                catch (error) {
                        tempLogBuffer[0] = "Erreur lors de l'envoi : $error";
                        updateLogs();

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
                                                buildDebugToggleButton()
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
                                                                sensors: getSensors("internal"),
                                                                isDebugMode: isDebugVisible
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        MySensors(
                                                                title: "Les Capteurs ModBus",
                                                                sensors: getSensors("modbus"),
                                                                isDebugMode: isDebugVisible
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        MySensors(
                                                                title: "Les Capteurs Stevenson",
                                                                sensors: getSensors("stevensonStatus").first.powerStatus == 2 ? getSensors("stevensonStatus") : getSensors("stevenson"),
                                                                isDebugMode: isDebugVisible
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
                                                isCapturing = true;
                                                buffer = "";
                                        }

                                        if (isCapturing && buffer.contains(communicationMessagePhoneEnd)) {
                                                isCapturing = false;
                                                final rawData = buffer
                                                        .replaceAll(communicationMessagePhoneStart, "")
                                                        .replaceAll(communicationMessagePhoneEnd, "")
                                                        .trim();

                                                // Si rawData contient <status>
                                                if (rawData.contains("<status>")) {
                                                        final lines = rawData.split('\n');
                                                        if (lines.length >= 3) {
                                                                final headers = lines[1].split(',').map((h) => h.trim()).toList();
                                                                final values = lines[2].split(',').map((v) => v.trim()).toList();

                                                                tempLogBuffer[1] = "Status:\n" + headers.asMap().entries.map((entry) {
                                                                                        final index = entry.key;
                                                                                        final header = entry.value.toUpperCase();
                                                                                        return "$header:    ${values[index]}";
                                                                                }
                                                                        ).join("\n");
                                                        }
                                                }

                                                // Si rawData contient <data>
                                                if (rawData.contains("<data>")) {
                                                        final lines = rawData.split('\n');
                                                        if (lines.length >= 3) {
                                                                final headers = lines[1].split(',').map((h) => h.trim()).toList();
                                                                final values = lines[2].split(',').map((v) => v.trim()).toList();

                                                                tempLogBuffer[2] = "\nValeurs:\n" + headers.asMap().entries.map((entry) {
                                                                                        final index = entry.key;
                                                                                        final header = entry.value.toUpperCase();
                                                                                        return "$header:    ${values[index]}";
                                                                                }
                                                                        ).join("\n");
                                                        }
                                                }

                                                updateLogs();

                                                // Remplacer les valeurs de sensors par les valeurs reçues
                                                if (rawData.contains("<data>")) {
                                                        populateSensorData(rawData); // Appel correct
                                                }

                                                // Mettre à jour les capteurs avec les données brutes (tout le temps)
                                                updateSensorsData(rawData);
                                                buffer = "";
                                        }
                                }
                        }
                );
        }

        void populateSensorData(String rawData) {
                // Séparer les lignes
                final lines = rawData.split('\n');
                if (lines.length < 3) return;

                // Extraire les en-têtes et les valeurs
                final headers = lines[1].split(',').map((h) => h.trim().toLowerCase()).toList();
                final values = lines[2].split(',').map((v) => v.trim()).toList();

                // Fonction générique pour mettre à jour les capteurs
                void updateSensorData(List<Sensors> sensors) {
                        for (var sensor in sensors) {
                                sensor.data.forEach((key, _) {
                                                final headerIndex = headers.indexOf(key.header.toLowerCase());
                                                if (headerIndex != -1) {
                                                        // Récupérer la valeur et la formater
                                                        if (key.header == "wind_direction_facing") {
                                                                final directionValue = int.tryParse(values[headerIndex]) ?? -1;
                                                                sensor.data[key] = getWindDirectionFacing(directionValue);
                                                        }
                                                        else {
                                                                final rawValue = double.tryParse(values[headerIndex]) ?? 0.0;
                                                                final formattedValue = rawValue.toStringAsFixed(2) + getUnitForHeader(key.header);
                                                                sensor.data[key] = formattedValue;
                                                        }
                                                }
                                        }
                                );
                        }
                }

                // Mettre à jour les différentes catégories de capteurs
                updateSensorData(internalSensors);
                updateSensorData(modBusSensors);
                updateSensorData(stevensonSensors);
        }

        // Méthode pour récupérer l'unité personnalisée en fonction du header
        String getUnitForHeader(String header) {
                switch (header.toLowerCase()) {
                        case "bme280_temperature":
                        case "bme280modbus_temperature":
                                return " °C";
                        case "bme280_pression":
                        case "bme280modbus_pression":
                                return " kPa";
                        case "bme280_altitude":
                                return " m";
                        case "bme280_humidity":
                        case "bme280modbus_humidity":
                                return " %";
                        case "lsm303_accel_x":
                        case "lsm303_accel_y":
                        case "lsm303_accel_z":
                                return " m/s²";
                        case "lsm303_roll":
                        case "lsm303_pitch":
                                return " °";
                        case "lsm303_accel_range":
                                return " g";
                        case "wind_speed":
                                return " m/s";
                        case "wind_direction_angle":
                                return " °";
                        case "asl20lux_lux":
                                return " lux";
                        default:
                        return ""; // Pas d'unité par défaut
                }
        }

        String getWindDirectionFacing(int value) {
                switch (value) {
                        case 0:
                        case 16:
                                return "Nord";
                        case 1:
                                return "Nord-nord-est";
                        case 2:
                                return "Nord-est";
                        case 3:
                                return "Est-nord-est";
                        case 4:
                                return "Est";
                        case 5:
                                return "Est-sud-est";
                        case 6:
                                return "Sud-est";
                        case 7:
                                return "Sud-sud-est";
                        case 8:
                                return "Sud";
                        case 9:
                                return "Sud-sud-ouest";
                        case 10:
                                return "Sud-ouest";
                        case 11:
                                return "Ouest-sud-ouest";
                        case 12:
                                return "Ouest";
                        case 13:
                                return "Ouest-nord-ouest";
                        case 14:
                                return "Nord-ouest";
                        case 15:
                                return "Nord-nord-ouest";
                        default:
                        return "Inconnu";
                }
        }

        Widget buildDebugMenu() {
                return Card(
                        child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                const Text("Logs de Debug (se rafraîchit tout seul):", style: TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                        height: 200,
                                                        child: ListView.builder(
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
                if (!rawData.contains(communicationMessageStatus)) return;

                // Extraire les données de statut
                final headers = rawData.split('\n')[1].split(',').map((h) => h.trim().toLowerCase()).toList();
                final values = rawData.split('\n')[2].split(',').map((v) => int.tryParse(v.trim()) ?? 0).toList();

                // Fonction générique pour mettre à jour les capteurs
                void updateSensorStatus(List<Sensors> sensors) {
                        for (var sensor in sensors) {
                                if (sensor.header == null) {
                                        continue; // Ignore les capteurs sans header
                                }

                                if (headers.contains(sensor.header!.toLowerCase())) {
                                        sensor.powerStatus = values[headers.indexOf(sensor.header!.toLowerCase())];
                                }
                                else {
                                        sensor.powerStatus = null; // Si le capteur n'est pas trouvé, on le met hors ligne
                                }
                        }
                }

                // Mettre à jour les capteurs internes, du vent et Stevenson
                updateSensorStatus(getSensors("internal"));
                updateSensorStatus(getSensors("modbus"));
                updateSensorStatus(getSensors("stevenson"));
                updateSensorStatus(getSensors("stevensonStatus"));

                // Mettre à jour les propriétés spécifiques de Stevenson
                final stevensonMapping = {
                        getSensors("stevenson").first.temp?.toLowerCase():(int status) => stevensonTemp = status,
                        getSensors("stevenson").first.hum?.toLowerCase():(int status) => stevensonHum = status,
                        getSensors("stevenson").first.pres?.toLowerCase():(int status) => stevensonPress = status
                };

                for (int i = 0; i < headers.length; i++) {
                        stevensonMapping[headers[i]]?.call(values[i]);
                }

                // Calculer le powerStatus global pour le capteur Stevenson principal
                getSensors("stevenson").first.powerStatus = max(stevensonTemp, max(stevensonHum, stevensonPress));
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

        void updateLogs() async {
                setState(() {
                                debugLogs.clear();
                                debugLogs.add("-----START LOG CHUNK-----");
                                debugLogs.addAll(tempLogBuffer);
                                debugLogs.add("\n-----END LOG CHUNK-----");
                        }
                );
        }
}