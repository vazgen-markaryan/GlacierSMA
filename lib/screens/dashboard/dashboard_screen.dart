import 'dart:async';
import '../../constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'components/sensors_data.dart';
import 'components/sensors_layout.dart';
import 'functions/data_reader.dart';
import 'functions/debug_log_manager.dart';
import '../connection/connection_screen.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/widgets/debug_data.dart';
import 'package:rev_glacier_sma_mobile/screens/dashboard/widgets/debug_toggle.dart';

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

        // DEBUG MOD
        bool isDebugVisible = false; // État pour afficher ou masquer les logs
        final DebugLogManager debugLogManager = DebugLogManager();

        // Suivi d'état pour le capteur Stevenson
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
                readMessage(
                        messageChannel: messageChannel,
                        sendMessage: sendMessage,
                        debugLogManager: debugLogManager,
                        getSensors: getSensors,
                        setTemp: (v) => stevensonTemp = v,
                        setHum: (v) => stevensonHum = v,
                        setPres: (v) => stevensonPress = v
                );

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
                        debugLogManager.setLogChunk(0, "Message envoyé : $message");
                        debugLogManager.updateLogs();

                        return isMessageSent;
                }
                catch (error) {
                        debugLogManager.setLogChunk(0, "\nErreur lors de l'envoi : $error\n");
                        debugLogManager.updateLogs();

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
                                                DebugToggleButton(
                                                        isDebugVisible: isDebugVisible,
                                                        onToggle: toggleDebugMode
                                                )
                                        ]
                                )
                        ),
                        body: SafeArea(
                                child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(defaultPadding),
                                        child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                        if (isDebugVisible) DebugData(debugLogManager: debugLogManager),
                                                        SizedBox(height: defaultPadding),
                                                        SensorsDiv(
                                                                title: "Les Capteurs Internes",
                                                                sensors: getSensors(SensorType.internal),
                                                                isDebugMode: isDebugVisible
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        SensorsDiv(
                                                                title: "Les Capteurs ModBus",
                                                                sensors: getSensors(SensorType.modbus),
                                                                isDebugMode: isDebugVisible
                                                        ),
                                                        SizedBox(height: defaultPadding),
                                                        SensorsDiv(
                                                                title: "Les Capteurs Stevenson",
                                                                sensors: getSensors(SensorType.stevensonStatus).first.powerStatus == 2 ? getSensors(SensorType.stevensonStatus) : getSensors(SensorType.stevenson),
                                                                isDebugMode: isDebugVisible
                                                        )
                                                ]
                                        )
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
}