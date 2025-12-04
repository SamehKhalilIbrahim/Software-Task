## 📹 Hardware Setup Demo

### 🔧 Short Hardware Video  
A quick demo showing the ESP32, sensor wiring, and live data transmission over BLE:

👉 **[Watch Hardware Setup Video](https://youtube.com/shorts/UkCGTZCc1YM)**

---

## 🚀 IoT End-to-End Architecture  
This project showcases a full pipeline from a physical sensor → mobile device → backend API.

### ✨ Features  
- 📟 **ESP32** collects real-time sensor readings  
- 📡 Sends data via **Bluetooth Low Energy (BLE)**  
- 📱 **Flutter app** connects and displays the latest value  
- 🔄 App syncs reading with **NestJS backend**  
- 🗄 Backend stores values and exposes API for latest reading  

---

## 📁 Repository Structure

### /hardware → ESP32 / Arduino firmware

### /app → Flutter mobile application

### /backend → NestJS REST API server

---

## 🌐 API Endpoint

| Method | Endpoint          | Description                |
|--------|--------------------|----------------------------|
| GET    | `/readings/latest` | Returns the latest reading |
| POST   | `/readings` | Sends values of two sensors to the backend |


---

## 🎥 Full Project Demo  
👉 **[Watch Full Demo Video](YOUR_LINK_HERE)**

---
