import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';

Future<void> showBluetoothDeviceDialog(BuildContext context) async {
        List<ScanResult> foundDevices = [];

        final subscription = FlutterBluePlus.scanResults.listen((results) {
                        foundDevices = results
                                .where((r) =>
                                        r.advertisementData.advName.contains("RevGlacierSMA"))
                                .toList();
                }
        );

        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

        // Affiche un popup immédiat
        bool dialogClosed = false;
        showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) {
                        return StatefulBuilder(
                                builder: (context, setState) {
                                        Future.delayed(const Duration(seconds: 2), () => setState(() {
                                                        }
                                                )); // Force refresh
                                        return AlertDialog(
                                                backgroundColor: secondaryColor,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: Text(
                                                        tr("connection.devices_found"),
                                                        style: const TextStyle(
                                                                color: primaryColor,
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold
                                                        )
                                                ),
                                                content: SizedBox(
                                                        width: double.maxFinite,
                                                        height: 300,
                                                        child: foundDevices.isEmpty
                                                                ? const Center(child: CircularProgressIndicator())
                                                                : ListView.builder(
                                                                        itemCount: foundDevices.length,
                                                                        itemBuilder: (context, index) {
                                                                                final result = foundDevices[index];
                                                                                final device = result.device;
                                                                                final name = result.advertisementData.localName.isNotEmpty
                                                                                        ? result.advertisementData.localName
                                                                                        : (device.name.isNotEmpty ? device.name : "Unknown (${device.id})");

                                                                                return Card(
                                                                                        color: backgroundColor,
                                                                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                        child: ListTile(
                                                                                                title: Text(
                                                                                                        name,
                                                                                                        style: const TextStyle(color: Colors.white, fontSize: 16)
                                                                                                ),
                                                                                                subtitle: Text("ID: ${device.remoteId}",
                                                                                                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                                                                                onTap: () async {
                                                                                                        try {
                                                                                                                await device.connect(timeout: const Duration(seconds: 5));
                                                                                                                if (!dialogClosed) Navigator.pop(context);
                                                                                                                FlutterBluePlus.stopScan();
                                                                                                                subscription.cancel();
                                                                                                                Navigator.pushReplacement(
                                                                                                                        context,
                                                                                                                        MaterialPageRoute(
                                                                                                                                builder: (_) => Home_Screen(
                                                                                                                                        plugin: null,
                                                                                                                                        isConnected: true,
                                                                                                                                        connectedDevices: []
                                                                                                                                )
                                                                                                                        )
                                                                                                                );
                                                                                                        }
                                                                                                        catch (_) {
                                                                                                                if (!dialogClosed) Navigator.pop(context);
                                                                                                                showCustomSnackBar(context, message: tr("connection.failed_to_connect"));
                                                                                                        }
                                                                                                }
                                                                                        )
                                                                                );
                                                                        }
                                                                )
                                                ),
                                                actions: [
                                                        TextButton(
                                                                onPressed: () {
                                                                        dialogClosed = true;
                                                                        FlutterBluePlus.stopScan();
                                                                        subscription.cancel();
                                                                        Navigator.pop(context);
                                                                },
                                                                child: Text(tr("cancel"), style: const TextStyle(color: primaryColor))
                                                        )
                                                ]
                                        );
                                }
                        );
                }
        );

        // Si après 15s aucun appareil, affiche un SnackBar
        await Future.delayed(const Duration(seconds: 15));
        if (foundDevices.isEmpty && !dialogClosed) {
                FlutterBluePlus.stopScan();
                subscription.cancel();
                Navigator.pop(context);
                showCustomSnackBar(context, message: tr("connection.no_device_found"));
        }
}