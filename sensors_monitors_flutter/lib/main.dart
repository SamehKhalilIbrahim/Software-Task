import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SensorMonitorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SensorMonitorPage extends StatefulWidget {
  @override
  _SensorMonitorPageState createState() => _SensorMonitorPageState();
}

class _SensorMonitorPageState extends State<SensorMonitorPage> {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  String lightValue = "0";
  String smokeValue = "0";

  List<ScanResult> scanResults = [];
  bool isScanning = false;

  final SERVICE_UUID = Guid("12345678-1234-1234-1234-1234567890AB");
  final CHARACTERISTIC_UUID = Guid("ABCD1234-1234-5678-1234-ABCDEF123456");

  @override
  void initState() {
    super.initState();
    startScan();
  }

  Future<void> postDataToAPI(double light, double smoke) async {
    final Map<String, dynamic> data = {
      // These keys MUST match the lightValue and smokeValue in your NestJS DTO
      'lightValue': light,
      'smokeValue': smoke,
    };

    print('Attempting to post: $data');

    try {
      final Dio dio = Dio();
      final response = await dio.post(
        "http://192.168.1.2:3000/readings",
        data: data, // Dio automatically handles JSON encoding of the Map
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ API Post Successful! Response: ${response.data}');
      } else {
        print(
          '❌ API Post Failed. Status: ${response.statusCode}, Body: ${response.data}',
        );
      }
      setState(() {
        print('Data posted: Light=$light, Smoke=$smoke');
      });
    } on DioException catch (e) {
      // Catch specific Dio errors (e.g., network failure, server error response)
      print('❌ Dio Error Posting Data: ${e.message}');
    } catch (e) {
      // Catch other unexpected errors
      print('❌ General Error Posting Data: $e');
    }
  }

  void startScan() async {
    setState(() => isScanning = true);
    scanResults.clear();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await Future.delayed(const Duration(seconds: 4));
    FlutterBluePlus.stopScan();

    setState(() => isScanning = false);
  }

  Future<void> connect(BluetoothDevice d) async {
    device = d;

    try {
      await device!.connect(timeout: const Duration(seconds: 8));
    } catch (e) {
      print("Retry BLE connect...");
      await device!.disconnect();
      await Future.delayed(const Duration(seconds: 1));
      await device!.connect(timeout: const Duration(seconds: 8));
    }
    await device!.requestMtu(100);
    List<BluetoothService> services = await device!.discoverServices();
    for (BluetoothService s in services) {
      if (s.uuid == SERVICE_UUID) {
        for (BluetoothCharacteristic c in s.characteristics) {
          if (c.uuid == CHARACTERISTIC_UUID) {
            characteristic = c;

            await c.setNotifyValue(true);

            c.lastValueStream.listen((data) {
              parseData(utf8.decode(data));
            });

            setState(() {});
            return;
          }
        }
      }
    }
  }

  void parseData(String text) {
    List parts = text.split("|");

    if (parts.length == 2) {
      lightValue = parts[0].split(":")[1];
      smokeValue = parts[1].split(":")[1];
    }

    setState(() {
      postDataToAPI(
        lightValue.isEmpty ? 0.0 : double.parse(lightValue),
        smokeValue.isEmpty ? 0.0 : double.parse(smokeValue),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ESP32 BLE Sensor Monitor"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: startScan),
        ],
      ),
      body: characteristic == null ? buildScanner() : buildSensorUI(),
    );
  }

  Widget buildScanner() {
    return Column(
      children: [
        if (isScanning) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final r = scanResults[index];
              return ListTile(
                title: Text(
                  r.device.platformName.isEmpty
                      ? "Unknown Device"
                      : r.device.platformName,
                ),
                subtitle: Text(r.device.remoteId.str),
                trailing: const Icon(Icons.bluetooth),
                onTap: () => connect(r.device),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildSensorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Light: $lightValue%", style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 20),
          Text("Smoke: $smokeValue%", style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 40),
          ElevatedButton(
            child: const Text("Disconnect"),
            onPressed: () {
              device?.disconnect();
              setState(() {
                characteristic = null;
                device = null;
              });
            },
          ),
        ],
      ),
    );
  }
}
