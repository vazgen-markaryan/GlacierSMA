import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDataReader {
        final BluetoothDevice device;
        late BluetoothService service;

        static const Map<String, String> uuids = {
                'id': '00debc9a-7856-3412-f0de-bc9a78563412',
                'status': '01debc9a-7856-3412-f0de-bc9a78563412',
                'data1': '02debc9a-7856-3412-f0de-bc9a78563412',
                'data2': '03debc9a-7856-3412-f0de-bc9a78563412',
                'active': '04debc9a-7856-3412-f0de-bc9a78563412',
                'config': '05debc9a-7856-3412-f0de-bc9a78563412'
        };

        BluetoothDataReader(this.device);

        Future<void> init() async {
                List<BluetoothService> services = await device.discoverServices();
                service = services.firstWhere((s) => s.uuid.toString().toLowerCase().contains("1815"));
        }

        // Tu vas maintenant lire tous les blocs séparément :
        Future<List<String>> readAllData() async {
                List<String> allBlocks = [];

                final id = await readChar(uuids['id']!);
                if (id.isNotEmpty) allBlocks.add("<id>\n$id");

                final status = await readChar(uuids['status']!);
                if (status.isNotEmpty) allBlocks.add("<status>\n$status");

                final data1 = await readChar(uuids['data1']!);
                final data2 = await readChar(uuids['data2']!);
                if (data1.isNotEmpty && data2.isNotEmpty) {
                        final dataBlock = "<data>\n$data1\n$data2";
                        allBlocks.add(dataBlock);
                }

                final active = await readChar(uuids['active']!);
                if (active.isNotEmpty) allBlocks.add("<active>\n$active");

                final config = await readChar(uuids['config']!);
                if (config.isNotEmpty) allBlocks.add("<config>\n$config");

                return allBlocks;
        }

        Future<String> readChar(String charUuid) async {
                final characteristic = service.characteristics.firstWhere(
                        (char) {
                                final searchedPrefix = charUuid.toLowerCase().substring(0, 8);
                                return char.uuid.toString().toLowerCase().contains(searchedPrefix);
                        },
                        orElse: () => throw Exception("Characteristic $charUuid not found")
                );

                final data = await characteristic.read();
                return utf8.decode(data);
        }
}