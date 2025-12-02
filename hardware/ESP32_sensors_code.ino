#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// ---- SENSOR PINS ----
#define LIGHT_SENSOR_PIN 34
#define SMOKE_SENSOR_PIN 35

// ---- BLE UUIDs ----
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890AB"
#define CHARACTERISTIC_UUID "ABCD1234-1234-5678-1234-ABCDEF123456"

BLECharacteristic *pCharacteristic;

// ---- BLE CALLBACKS ----
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    Serial.println("📱 Device connected");
  }

  void onDisconnect(BLEServer* pServer) {
    Serial.println("📴 Device disconnected — restarting advertising...");
    BLEDevice::startAdvertising();
  }
};

void setup() {
  Serial.begin(9600);

  // Init BLE
  BLEDevice::init("ESP32_Sensors");

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE characteristic
  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_NOTIFY
  );

  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  BLEDevice::startAdvertising();

  Serial.println("🚀 BLE Started — waiting for device...");
}

void loop() {
  // Read light sensor (0 → 4095)
  int lightRaw = analogRead(LIGHT_SENSOR_PIN);
  int lightPercent = map(lightRaw, 0, 4095, 100, 0);

  // Read smoke sensor
  int smokeRaw = analogRead(SMOKE_SENSOR_PIN);
  int smokePercent = map(smokeRaw, 0, 4095, 0, 100);

  // Build BLE packet
  String packet =
    "LIGHT:" + String(lightPercent) +
    "|SMOKE:" + String(smokePercent);

  // Send BLE data
  pCharacteristic->setValue(packet.c_str());
  pCharacteristic->notify();

  // Print to serial
  Serial.println(packet);

  delay(300);
}

// #include "BluetoothSerial.h"

// // Check if Bluetooth is available
// #if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
// #error Bluetooth is not enabled! Please run `make menuconfig` to enable it
// #endif

// // Pin definitions
// #define LIGHT_SENSOR_PIN 34
// #define SMOKE_SENSOR_PIN 35

// // Smoke sensor settings
// #define SMOKE_THRESHOLD 2000
// #define PREHEAT_TIME 10

// // Bluetooth Serial object
// BluetoothSerial SerialBT;

// void setup() {
//   Serial.begin(9600);
//   delay(1000);
  
//   // Initialize Bluetooth
//   SerialBT.begin("ESP32_Sensors");  // Bluetooth device name
  
//   Serial.println("\n================================");
//   Serial.println("Light & Smoke Sensor with BT");
//   Serial.println("================================");
//   Serial.println("📱 Bluetooth: ESP32_Sensors");
//   Serial.println("================================\n");
  
//   SerialBT.println("\n================================");
//   SerialBT.println("ESP32 Sensors Connected!");
//   SerialBT.println("================================\n");
  
//   analogReadResolution(12);
  
//   Serial.println("⚠️  Smoke sensor preheating...");
//   SerialBT.println("⚠️  Preheating smoke sensor...");
//   Serial.print("Please wait ");
//   Serial.print(PREHEAT_TIME);
//   Serial.println(" seconds\n");
  
//   // Preheat countdown
//   for (int i = PREHEAT_TIME; i > 0; i--) {
//     if (i % 20 == 0 || i <= 10) {
//       Serial.print("Preheating: ");
//       Serial.print(i);
//       Serial.println("s");
      
//       SerialBT.print("Preheating: ");
//       SerialBT.print(i);
//       SerialBT.println("s");
//     }
//     delay(1000);
//   }
  
//   Serial.println("\n✅ Sensors ready!\n");
//   SerialBT.println("\n✅ Sensors ready!");
//   SerialBT.println("Sending data every 2 seconds...\n");
//   delay(1000);
// }

// void loop() {
//   // Read light sensor
//   int lightRaw = analogRead(LIGHT_SENSOR_PIN);
//   int lightPercent = map(lightRaw, 0, 4095, 100, 0);
  
//   // Read smoke sensor
//   int smokeRaw = analogRead(SMOKE_SENSOR_PIN);
//   int smokePercent = map(smokeRaw, 0, 4095, 0, 100);
  
//   // Determine light status
//   String lightStatus;
//   if (lightPercent < 20) {
//     lightStatus = "🌙 DARK";
//   } else if (lightPercent < 50) {
//     lightStatus = "🌤️ DIM";
//   } else if (lightPercent < 80) {
//     lightStatus = "☀️ BRIGHT";
//   } else {
//     lightStatus = "🔆 VERY BRIGHT";
//   }
  
//   // Determine smoke status
//   String smokeStatus;
//   if (smokeRaw < 500) {
//     smokeStatus = "✅ CLEAN AIR";
//   } else if (smokeRaw < 1000) {
//     smokeStatus = "⚠️ LOW GAS";
//   } else if (smokeRaw < 2000) {
//     smokeStatus = "🔶 MODERATE GAS";
//   } else if (smokeRaw < 3000) {
//     smokeStatus = "🔴 HIGH GAS";
//   } else {
//     smokeStatus = "🚨 DANGER!";
//   }
  
//   // Display on Serial Monitor
//   Serial.println("======= SENSOR READINGS =======");
//   Serial.print("💡 Light: ");
//   Serial.print(lightPercent);
//   Serial.print("% | ");
//   Serial.println(lightStatus);
//   Serial.print("🔥 Smoke: ");
//   Serial.print(smokePercent);
//   Serial.print("% | ");
//   Serial.println(smokeStatus);
  
//   // Send via Bluetooth
//   SerialBT.println("======= SENSOR DATA =======");
//   SerialBT.print("💡 Light: ");
//   SerialBT.print(lightPercent);
//   SerialBT.print("% | ");
//   SerialBT.println(lightStatus);
//   SerialBT.print("🔥 Smoke: ");
//   SerialBT.print(smokePercent);
//   SerialBT.print("% | ");
//   SerialBT.println(smokeStatus);
  
//   // Alert check
//   if (smokeRaw > SMOKE_THRESHOLD) {
//     Serial.println("\n🚨 ALERT! SMOKE/GAS DETECTED! 🚨");
//     SerialBT.println("\n🚨 ALERT! SMOKE DETECTED! 🚨");
//   }
  
//   Serial.println("===============================\n");
//   SerialBT.println("===========================\n");
  
//   delay(2000);
// }