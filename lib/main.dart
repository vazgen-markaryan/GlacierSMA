//         void readMessage() {
//                 messageChannel?.receiveBroadcastStream().listen((event) {
//                                 if (event is Uint8List) {
//                                         final chunk = String.fromCharCodes(event);
//                                         buffer += chunk;
//
//                                         if (buffer.contains("<phone_start>")) {
//                                                 isCapturing = true;
//                                                 buffer = "";
//                                         }
//                                         if (isCapturing && buffer.contains("<phone_end>")) {
//                                                 isCapturing = false;
//                                                 final rawData = buffer.replaceAll("<phone_start>", "").replaceAll("<phone_end>", "").trim();
//                                                 List<String> lines = rawData.split('\n').map((e) => e.trim()).toList();
//                                                 if (lines.isNotEmpty) {
//                                                         if (lines[0] == "<data>" && lines.length >= 3) {
//                                                                 final headers = lines[1].split(',');
//                                                                 final values = lines[2].split(',');
//                                                                 final dataMap = Map.fromIterables(headers, values);
//                                                                 setState(() => receivedMessage = "SENSORS DATA:\n$dataMap");
//                                                         }
//                                                         else if (lines[0] == "<status>" && lines.length >= 3) {
//                                                                 final headers = lines[1].split(',');
//                                                                 final values = lines[2].split(',');
//                                                                 final statusMap = Map.fromIterables(headers, values);
//                                                                 setState(() => receivedMessage = "SENSORS STATUS:\n$statusMap");
//                                                         }
//                                                 }
//                                                 buffer = "";
//                                         }
//                                 }
//                         }
//                 );
//         }

//         Widget buildMessageSection() {
//                 if (!isConnected) {
//                         return const SizedBox();
//                 }
//                 return Card(
//                         child: Padding(
//                                 padding: const EdgeInsets.all(12.0),
//                                 child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                                 const Text("Reception du data:", style: TextStyle(fontWeight: FontWeight.bold)),
//                                                 const SizedBox(height: 8),
//                                                 Text(receivedMessage, style: const TextStyle(fontSize: 16))
//                                         ]
//                                 )
//                         )
//                 );
//         }


import 'package:flutter/material.dart';
import 'package:rev_glacier_sma_mobile/dashboard/dashboard_screen.dart';
import 'connection/connection_screen.dart';
import 'constants.dart';

void main() {
        runApp(const MyApp());
}

class MyApp extends StatelessWidget {
        const MyApp({super.key});

        @override
        Widget build(BuildContext context) {
                return MaterialApp(
                        debugShowCheckedModeBanner: false,
                        title: 'Glacier SMA',
                        theme: ThemeData.dark().copyWith(
                                scaffoldBackgroundColor: bgColor,
                                textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
                                canvasColor: secondaryColor
                        ),
                        home: const ConnectionScreen()
                        // home: const DashboardScreen(flutterSerialCommunicationPlugin: null, isConnected: false, connectedDevices: [])
                );
        }
}