import 'package:flutter/material.dart';

class GlobalConnectionState {
        // Singleton
        static final GlobalConnectionState instance = GlobalConnectionState._();

        GlobalConnectionState._();

        // Notifier central
        final ValueNotifier<ConnectionMode> modeNotifier = ValueNotifier(ConnectionMode.none);

        // Méthodes
        void setUsbConnected() => modeNotifier.value = ConnectionMode.usb;
        void setBluetoothConnected() => modeNotifier.value = ConnectionMode.bluetooth;
        void setDisconnected() => modeNotifier.value = ConnectionMode.none;

        // Accès rapide
        ConnectionMode get currentMode => modeNotifier.value;
}

enum ConnectionMode {
        none, usb, bluetooth
}