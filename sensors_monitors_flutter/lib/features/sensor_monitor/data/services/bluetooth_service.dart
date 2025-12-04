import 'package:dio/dio.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../model/sensor_data.dart';

class BleService {
  final Guid serviceUUID = Guid("12345678-1234-1234-1234-1234567890AB");
  final Guid charUUID = Guid("ABCD1234-1234-5678-1234-ABCDEF123456");

  Stream<List<ScanResult>> scan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    return FlutterBluePlus.scanResults;
  }

  Future<BluetoothCharacteristic?> connect(BluetoothDevice device) async {
    await device.connect(timeout: const Duration(seconds: 8));
    await device.requestMtu(100);

    List<BluetoothService> services = await device.discoverServices();
    for (var s in services) {
      if (s.uuid == serviceUUID) {
        for (var c in s.characteristics) {
          if (c.uuid == charUUID) return c;
        }
      }
    }
    return null;
  }

  /// Expected: Light:50|Smoke:20
  Map<String, double> parse(String data) {
    final parts = data.split("|");
    final l = parts[0].split(":")[1];
    final s = parts[1].split(":")[1];

    return {
      "light": double.tryParse(l) ?? 0.0,
      "smoke": double.tryParse(s) ?? 0.0,
    };
  }

  Future<void> postDataToAPI(SensorData data) async {
    try {
      final response = await Dio().post(
        "http://192.168.1.2:3000/readings",
        data: data.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ API Post Successful: ${data.toJson()}');
      } else {
        print('❌ API Post Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error posting data: $e');
    }
  }
}
