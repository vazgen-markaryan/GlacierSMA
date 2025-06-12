import 'message_service.dart';
import '../screens/debug_log/debug_log_updater.dart';

/// Service de message factice pour les environnements sans Bluetooth.
class DummyMessageService extends MessageService {
        DummyMessageService() : super(plugin: null, debugLogManager: DebugLogUpdater());

        @override
        Future<bool> sendString(String message) async {
                return false;  // On ne fait rien en Bluetooth
        }

        @override
        Future<bool> sendStationName(String name) async {
                return false;
        }
}