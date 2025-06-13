import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/global_state.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_popup.dart';
import 'package:rev_glacier_sma_mobile/utils/custom_snackbar.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:rev_glacier_sma_mobile/screens/home/home_screen.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/connection/connection_screen.dart';

/// Abstraction unifiée
abstract class DeviceCandidate {
        String get displayName;
        String get uniqueId;
        Future<bool> connect(BuildContext context);
}

/// USB wrapper
class UsbDeviceCandidate extends DeviceCandidate {
        final DeviceInfo device;
        final FlutterSerialCommunication plugin;

        UsbDeviceCandidate(this.device, this.plugin);

        @override
        String get displayName => device.productName;

        @override
        String get uniqueId => device.deviceId.toString();

        @override
        Future<bool> connect(BuildContext context) async {
                return await plugin.connect(device, 115200);
        }
}

/// BLE wrapper
class BleDeviceCandidate extends DeviceCandidate {
        final BluetoothDevice device;

        BleDeviceCandidate(this.device);

        @override
        String get displayName => device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString();

        @override
        String get uniqueId => device.remoteId.toString();

        @override
        Future<bool> connect(BuildContext context) async {
                await device.connect(timeout: const Duration(seconds: 8));
                return true;
        }
}

/// Popup unifiée pour tous types de devices
Future<void> showDeviceSelectionDialog(
        BuildContext context,
        ValueNotifier<List<DeviceCandidate>> devicesNotifier
) async {
        ValueNotifier<String?> connectingDeviceId = ValueNotifier(null);

        showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => CustomPopup(
                        title: tr("connection.devices_found"),
                        content: ValueListenableBuilder<List<DeviceCandidate>>(
                                valueListenable: devicesNotifier,
                                builder: (context, devices, _) {
                                        if (devices.isEmpty) {
                                                return const Center(child: CircularProgressIndicator());
                                        }
                                        else {
                                                return Column(
                                                        children: devices.map(
                                                                (candidate) {
                                                                        return Card(
                                                                                color: backgroundColor,
                                                                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                                                child: ListTile(
                                                                                        title: Text(candidate.displayName, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                                                                        subtitle: Text("ID: ${candidate.uniqueId}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                                                                        trailing: ValueListenableBuilder<String?>(
                                                                                                valueListenable: connectingDeviceId,
                                                                                                builder: (context, currentId, _) {
                                                                                                        if (currentId == candidate.uniqueId) {
                                                                                                                return const SizedBox(
                                                                                                                        width: 24, height: 24,
                                                                                                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                                                                                                );
                                                                                                        }
                                                                                                        return const SizedBox.shrink();
                                                                                                }
                                                                                        ),
                                                                                        onTap: () async {
                                                                                                connectingDeviceId.value = candidate.uniqueId;

                                                                                                final success = await candidate.connect(context);
                                                                                                if (success) {
                                                                                                        Navigator.pushReplacement(
                                                                                                                context,
                                                                                                                MaterialPageRoute(
                                                                                                                        builder: (_) {
                                                                                                                                if (candidate is UsbDeviceCandidate) {
                                                                                                                                        GlobalConnectionState.instance.setUsbConnected();
                                                                                                                                        return Home_Screen(
                                                                                                                                                plugin: candidate.plugin,
                                                                                                                                                connectedDevices: [candidate.device]
                                                                                                                                        );
                                                                                                                                }
                                                                                                                                else if (candidate is BleDeviceCandidate) {
                                                                                                                                        GlobalConnectionState.instance.setBluetoothConnected();
                                                                                                                                        return Home_Screen(
                                                                                                                                                plugin: null,
                                                                                                                                                connectedDevices: [],
                                                                                                                                                bluetoothDevice: candidate.device
                                                                                                                                        );
                                                                                                                                }
                                                                                                                                else {
                                                                                                                                        return const ConnectionScreen();
                                                                                                                                }
                                                                                                                        }
                                                                                                                )
                                                                                                        );
                                                                                                }
                                                                                                else {
                                                                                                        connectingDeviceId.value = null;
                                                                                                        Navigator.pop(context);
                                                                                                        showCustomSnackBar(context, message: tr("connection.failed_to_connect"));
                                                                                                }
                                                                                        }
                                                                                )
                                                                        );
                                                                }
                                                        ).toList()
                                                );
                                        }
                                }
                        ),
                        actions: []
                )
        );
}

/// Scan USB
Future<void> scanUsbDevices(BuildContext context, FlutterSerialCommunication plugin) async {
        ValueNotifier<List<DeviceCandidate>> devicesNotifier = ValueNotifier([]);

        // Démarre la popup immédiatement (affiche "Recherche...")
        showDeviceSelectionDialog(context, devicesNotifier);

        // Pendant 10 secondes, on scanne les USB chaque 500ms
        final endTime = DateTime.now().add(const Duration(seconds: 10));

        while (DateTime.now().isBefore(endTime)) {
                final devices = await plugin.getAvailableDevices();
                final compatible = devices
                        .where((device) => device.productName.contains('RevGlacierSMA'))
                        .map((device) => UsbDeviceCandidate(device, plugin))
                        .toList();

                devicesNotifier.value = compatible;

                // Si au moins 1 device trouvé, on arrête la boucle immédiatement
                if (compatible.isNotEmpty) break;

                await Future.delayed(const Duration(milliseconds: 500));
        }
}

/// Scan BLE
Future<void> scanBleDevices(BuildContext context) async {

        // DEMANDE LES PERMISSIONS
        bool granted = await requestBluetoothPermissions(context);
        if (!granted) return;

        BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
        ValueNotifier<List<DeviceCandidate>> devicesNotifier = ValueNotifier([]);

        if (state != BluetoothAdapterState.on) {
                await FlutterBluePlus.turnOn();
                state = await FlutterBluePlus.adapterState.first;

                if (state != BluetoothAdapterState.on) {
                        showCustomSnackBar(context, message: tr("connection.bluetooth_required"));
                        return;
                }
        }

        final subscription = FlutterBluePlus.scanResults.listen(
                (results) {
                        final foundDevices = results
                                .where((result) => result.advertisementData.advName.contains("RevGlacierSMA"))
                                .map((result) => BleDeviceCandidate(result.device))
                                .toList();

                        devicesNotifier.value = [...foundDevices];
                }
        );

        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

        // On affiche le popup immédiatement et il se mettra à jour
        await showDeviceSelectionDialog(context, devicesNotifier);

        await Future.delayed(const Duration(seconds: 15));
        FlutterBluePlus.stopScan();
        subscription.cancel();
}

/// Déconnexion universelle
Future<bool> showDisconnectPopup({
        required BuildContext context,
        required FlutterSerialCommunication? plugin,
        bool requireConfirmation = false
}) async {
        if (requireConfirmation) {
                final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => CustomPopup(
                                title: tr("connection.disconnect"),
                                content: Text(tr("connection.disconnect_confirmation"), style: const TextStyle(color: Colors.white)),
                                actions: [
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: Text(tr("no"), style: const TextStyle(color: primaryColor))
                                        ),
                                        TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: Text(tr("yes"), style: const TextStyle(color: primaryColor))
                                        )
                                ]
                        )
                );

                if (result == true) {
                        await plugin?.disconnect();
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConnectionScreen()));
                        return true;
                }
                return false;
        }

        await plugin?.disconnect();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConnectionScreen()));
        return true;
}

Future<bool> requestBluetoothPermissions(BuildContext context) async {
        // Android 12+ permissions
        final permissions = [
                Permission.bluetoothScan,
                Permission.bluetoothConnect,
                Permission.locationWhenInUse
        ];

        Map<Permission, PermissionStatus> statuses = await permissions.request();

        // Vérifie si au moins un est refusé
        bool allGranted = statuses.values.every((status) => status.isGranted);

        if (!allGranted) {
                showCustomSnackBar(context, message: tr("connection.permissions_required"));
                return false;
        }

        return true;
}