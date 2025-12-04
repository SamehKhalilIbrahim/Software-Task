import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      home: SensorMonitorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SensorMonitorPage extends StatefulWidget {
  @override
  _SensorMonitorPageState createState() => _SensorMonitorPageState();
}

class _SensorMonitorPageState extends State<SensorMonitorPage>
    with TickerProviderStateMixin {
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  String lightValue = "0";
  String smokeValue = "0";

  List<ScanResult> scanResults = [];
  bool isScanning = false;

  late AnimationController _pulseController;
  late AnimationController _rotationController;

  final SERVICE_UUID = Guid("12345678-1234-1234-1234-1234567890AB");
  final CHARACTERISTIC_UUID = Guid("ABCD1234-1234-5678-1234-ABCDEF123456");

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    startScan();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> postDataToAPI(double light, double smoke) async {
    final Map<String, dynamic> data = {
      'lightValue': light,
      'smokeValue': smoke,
    };

    print('Attempting to post: $data');

    try {
      final Dio dio = Dio();
      final response = await dio.post(
        "http://192.168.1.2:3000/readings",
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ API Post Successful! Response: ${response.data}');
      } else {
        print(
          '❌ API Post Failed. Status: ${response.statusCode}, Body: ${response.data}',
        );
      }
    } on DioException catch (e) {
      print('❌ Dio Error Posting Data: ${e.message}');
    } catch (e) {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF1D1E33),
              const Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: characteristic == null
                    ? buildScanner()
                    : buildSensorUI(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.sensors, size: 28),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Sensor Monitor",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: RotationTransition(
              turns: _rotationController,
              child: const Icon(Icons.refresh, size: 28),
            ),
            onPressed: startScan,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildScanner() {
    return Column(
      children: [
        if (isScanning)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                minHeight: 6,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                "Available Devices",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 10),
              if (isScanning)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: scanResults.isEmpty && !isScanning
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No devices found",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: scanResults.length,
                  itemBuilder: (context, index) {
                    final r = scanResults[index];
                    return _buildDeviceCard(r);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => connect(result.device),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400.withOpacity(0.3),
                        Colors.purple.shade400.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bluetooth, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.device.platformName.isEmpty
                            ? "Unknown Device"
                            : result.device.platformName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        result.device.remoteId.str,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSensorUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSensorCard(
              title: "Light Intensity",
              value: lightValue,
              unit: "%",
              icon: Icons.wb_sunny,
              gradient: [Colors.amber.shade400, Colors.orange.shade600],
              glowColor: Colors.amber,
            ),
            const SizedBox(height: 25),
            _buildSensorCard(
              title: "Smoke Level",
              value: smokeValue,
              unit: "%",
              icon: Icons.cloud,
              gradient: [Colors.purple.shade400, Colors.pink.shade400],
              glowColor: Colors.purple,
            ),
            const SizedBox(height: 40),
            _buildDisconnectButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required List<Color> gradient,
    required Color glowColor,
  }) {
    final percentage = double.tryParse(value) ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: CircularGlowPainter(
                          progress: percentage / 100,
                          glowColor: glowColor,
                          pulseValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: glowColor.withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            device?.disconnect();
            setState(() {
              characteristic = null;
              device = null;
            });
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_disabled, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Disconnect",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircularGlowPainter extends CustomPainter {
  final double progress;
  final Color glowColor;
  final double pulseValue;

  CircularGlowPainter({
    required this.progress,
    required this.glowColor,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    canvas.drawCircle(center, radius - 7.5, bgPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.2 + pulseValue * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7.5),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [glowColor, glowColor.withOpacity(0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7.5),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularGlowPainter oldDelegate) =>
      progress != oldDelegate.progress || pulseValue != oldDelegate.pulseValue;
}
