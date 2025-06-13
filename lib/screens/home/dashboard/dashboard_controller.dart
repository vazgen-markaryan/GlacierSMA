import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rev_glacier_sma_mobile/utils/constants.dart';
import 'package:rev_glacier_sma_mobile/utils/message_service.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:rev_glacier_sma_mobile/screens/home/sensors/sensors_data.dart';
import 'package:rev_glacier_sma_mobile/screens/debug_log/debug_log_updater.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/data_processor.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/serial_data_reader.dart';
import 'package:rev_glacier_sma_mobile/screens/home/data_managers/bluetooth_data_reader.dart';

enum ConnectionType {
        serial, bluetooth
}

class DashboardController {
        final DebugLogUpdater debugLogManager;
        final void Function(String reason) onFatalReceived;
        final ValueNotifier<double?> batteryVoltage = ValueNotifier(null);
        final ValueNotifier<Map<String, double?>> ramNotifier = ValueNotifier({'ram_stack': null, 'ram_heap': null});
        final ValueNotifier<RawData?> firmwareNotifier = ValueNotifier(null);
        final ValueNotifier<int?> activeMaskNotifier = ValueNotifier(null);
        final ValueNotifier<RawData?> configNotifier = ValueNotifier(null);
        final ValueNotifier<int> iterationNotifier = ValueNotifier(0);
        final ValueNotifier<bool> isInitialLoading = ValueNotifier(true);
        final Stopwatch connectionStopwatch = Stopwatch();

        // Variables spécifiques selon le type
        final ConnectionType type;
        final FlutterSerialCommunication? plugin;
        final List<DeviceInfo>? connectedDevices;
        final MessageService? messageService;
        final void Function(Duration elapsed)? onConnectionLost;
        final BluetoothDevice? bluetoothDevice;

        Timer? pingTimer;
        EventChannel? messageChannel;
        BluetoothDataReader? dataReader;
        Timer? pollingTimer;
        StreamSubscription<BluetoothConnectionState>? bleConnectionSubscription;

        DashboardController.serial({
                required this.plugin,
                required this.connectedDevices,
                required this.messageService,
                required this.onConnectionLost,
                required this.debugLogManager,
                required this.onFatalReceived
        }) : type = ConnectionType.serial,
                bluetoothDevice = null;

        DashboardController.bluetooth({
                required this.bluetoothDevice,
                required this.debugLogManager,
                required this.onFatalReceived,
                required this.onConnectionLost
        }) : type = ConnectionType.bluetooth,
                plugin = null,
                connectedDevices = null,
                messageService = null;

        Future<void> init(void Function() onDataReceived, BuildContext context) async {
                connectionStopwatch.start();

                if (type == ConnectionType.serial) {
                        // MODE SÉRIE
                        messageChannel = plugin?.getSerialMessageListener();
                        plugin?.setDTR(true);

                        readMessage(
                                messageChannel: messageChannel,
                                sendAndroidMessage: messageService!.sendString,
                                debugLogManager: debugLogManager,
                                getSensors: getSensors,
                                onDataReceived: () {
                                        final hasData = [
                                                ...getSensors(SensorType.internal),
                                                ...getSensors(SensorType.modbus)
                                        ].any((sensor) => sensor.powerStatus != null);
                                        if (hasData) isInitialLoading.value = false;
                                        onDataReceived();
                                },
                                batteryVoltage: batteryVoltage,
                                onIdReceived: (id) => firmwareNotifier.value = id,
                                onActiveReceived: (mask) => activeMaskNotifier.value = mask,
                                onFatalReceived: (reason) => onFatalReceived(reason),
                                onConfigReceived: (config) => configNotifier.value = config,
                                iterationNotifier: iterationNotifier,
                                ramNotifier: ramNotifier
                        );

                        // PING USB pour perte de connexion
                        pingTimer = Timer.periodic(const Duration(seconds: 2), 
                                (_) async {
                                        final ok = await messageService!.sendString(communicationMessageAndroid);
                                        if (!ok) {
                                                pingTimer?.cancel();
                                                connectionStopwatch.stop();
                                                onConnectionLost!(connectionStopwatch.elapsed);
                                        }
                                }
                        );

                        messageService!.sendString("<info>");
                }

                if (type == ConnectionType.bluetooth) {
                        // MODE BLUETOOTH
                        dataReader = BluetoothDataReader(bluetoothDevice!);
                        await dataReader!.init();

                        // ATTENTION: Ici on écoute la perte de connexion BLE
                        bleConnectionSubscription = bluetoothDevice!.connectionState.listen(
                                (state) {
                                        if (state == BluetoothConnectionState.disconnected) {
                                                print("🔌 BLE disconnected (listener)");
                                                pollingTimer?.cancel();
                                                connectionStopwatch.stop();
                                                if (onConnectionLost != null) {
                                                        onConnectionLost!(connectionStopwatch.elapsed);
                                                }
                                        }
                                }
                        );

                        pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
                                        if (!context.mounted) return;

                                        final rawDataList = await dataReader!.readAllData();
                                        for (var singleRaw in rawDataList) {
                                                processRawData(
                                                        rawData: singleRaw,
                                                        debugLogManager: debugLogManager,
                                                        getSensors: getSensors,
                                                        onDataReceived: () {
                                                                final hasData = [
                                                                        ...getSensors(SensorType.internal),
                                                                        ...getSensors(SensorType.modbus)
                                                                ].any((sensor) => sensor.powerStatus != null);
                                                                if (hasData) isInitialLoading.value = false;
                                                                onDataReceived();
                                                        },
                                                        batteryVoltage: batteryVoltage,
                                                        onIdReceived: (id) => firmwareNotifier.value = id,
                                                        onActiveReceived: (mask) => activeMaskNotifier.value = mask,
                                                        onFatalReceived: (reason) => onFatalReceived(reason),
                                                        onConfigReceived: (config) => configNotifier.value = config,
                                                        iterationNotifier: iterationNotifier,
                                                        ramNotifier: ramNotifier
                                                );
                                        }
                                }
                        );
                }
        }

        void dispose() {
                pingTimer?.cancel();
                pollingTimer?.cancel();
                bleConnectionSubscription?.cancel();
                isInitialLoading.dispose();
                batteryVoltage.dispose();
                firmwareNotifier.dispose();
                activeMaskNotifier.dispose();
                configNotifier.dispose();
                ramNotifier.dispose();
                iterationNotifier.dispose();
        }
}