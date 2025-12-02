import 'dart:convert';
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

  String lightValue = "--";
  String smokeValue = "--";

  List<ScanResult> scanResults = [];
  bool isScanning = false;

  final SERVICE_UUID = Guid("12345678-1234-1234-1234-1234567890AB");
  final CHARACTERISTIC_UUID = Guid("ABCD1234-1234-5678-1234-ABCDEF123456");

  @override
  void initState() {
    super.initState();
    startScan();
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

    await device!.connect(timeout: const Duration(seconds: 10));

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

    setState(() {});
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
