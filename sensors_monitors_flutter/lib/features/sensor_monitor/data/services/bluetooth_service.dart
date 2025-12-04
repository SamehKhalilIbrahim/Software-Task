// bluetooth_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../model/sensor_data.dart';

class BleService {
  // Scan for BLE devices
  Stream<List<ScanResult>> scan() async* {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception("Bluetooth not supported on this device");
    }

    // Check if Bluetooth is turned on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception("Please turn on Bluetooth");
    }

    List<ScanResult> results = [];

    // Listen to scan results
    final subscription = FlutterBluePlus.scanResults.listen((scanResults) {
      results = scanResults;
    });

    try {
      // Start scanning with a timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // Emit results periodically during scan
      for (int i = 0; i < 4; i++) {
        await Future.delayed(const Duration(seconds: 1));
        yield results;
      }

      // Stop scanning
      await FlutterBluePlus.stopScan();

      // Emit final results
      yield results;
    } finally {
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  // Connect to device and return characteristic
  Future<BluetoothCharacteristic?> connect(BluetoothDevice device) async {
    try {
      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 15));

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Replace these with your actual ESP32 UUIDs
      const serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
      const characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

      // Find the target characteristic
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                characteristicUuid.toLowerCase()) {
              return char;
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
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
