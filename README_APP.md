# 🐠 Aquarium Heater Monitor App

Aplikasi Flutter untuk monitoring dan kontrol sistem heater aquarium berbasis ESP32 dengan komunikasi MQTT.

## 📱 Fitur Aplikasi

### 1. **Monitoring Real-time**
   - **Suhu Air**: Monitoring suhu air secara real-time (°C)
   - **Turbidity**: Monitoring tingkat kekeruhan air (Voltage)
   - **Status Heater**: Menampilkan status ON/OFF heater
   - **Mode Kontrol**: Menampilkan mode AUTO/MANUAL

### 2. **Grafik Temperature**
   - Grafik real-time untuk trend suhu air
   - Menyimpan 20 data point terakhir
   - Tampilan grafik yang smooth dengan gradient

### 3. **Kontrol Heater**
   - **Mode AUTO**: ESP32 mengontrol heater otomatis berdasarkan suhu (27-30°C)
   - **Mode ON**: Nyalakan heater secara manual
   - **Mode OFF**: Matikan heater secara manual

### 4. **Indikator Visual**
   - Color coding untuk suhu:
     - 🔵 Biru: < 27°C (terlalu dingin)
     - 🟢 Hijau: 27-30°C (optimal)
     - 🔴 Merah: > 30°C (terlalu panas)
   - Color coding untuk turbidity:
     - 🟢 Hijau: < 1.5V (jernih)
     - 🟠 Orange: 1.5-2.5V (sedikit keruh)
     - 🔴 Merah: > 2.5V (keruh)
   - Status koneksi MQTT (Online/Offline)

## 🏗️ Arsitektur Aplikasi

```
lib/
├── main.dart                      # Entry point aplikasi
├── providers/
│   └── mqtt_provider.dart         # State management & MQTT logic
├── screens/
│   └── home_screen.dart           # Halaman utama aplikasi
└── widgets/
    ├── sensor_card.dart           # Widget untuk menampilkan data sensor
    ├── control_card.dart          # Widget untuk kontrol heater
    └── temperature_chart.dart     # Widget grafik suhu
```

## 🔧 Konfigurasi MQTT

### Broker MQTT
- **Broker**: `broker.hivemq.com`
- **Port**: `1883`
- **Client ID**: Auto-generated (FlutterAquarium_timestamp)

### MQTT Topics

#### Subscribe Topics (Aplikasi Menerima Data):
```
heater/temperature    # Suhu air dari DS18B20 (°C)
heater/turbidity      # Turbidity voltage (V)
heater/status         # Status heater (ON/OFF/AUTO/connected)
```

#### Publish Topics (Aplikasi Mengirim Perintah):
```
heater/control        # Kontrol heater (ON/OFF/AUTO)
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  mqtt_client: ^10.11.1      # MQTT communication
  provider: ^6.1.5+1          # State management
  google_fonts: ^6.3.2        # Custom fonts
  fl_chart: ^1.1.1            # Chart visualization
  intl: ^0.20.2               # Date/time formatting
```

## 🚀 Instalasi & Menjalankan Aplikasi

### Prasyarat
1. Flutter SDK (versi 3.9.2 atau lebih tinggi)
2. Android Studio / VS Code dengan Flutter extension
3. Emulator Android atau perangkat fisik
4. ESP32 yang sudah di-program dan terhubung ke WiFi

### Langkah Instalasi

1. **Clone atau Download Project**
   ```bash
   cd aquariummonitor
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Pastikan ESP32 Sudah Berjalan**
   - Upload kode ESP32
   - Pastikan ESP32 terhubung ke WiFi
   - Pastikan ESP32 terhubung ke broker MQTT

4. **Jalankan Aplikasi**
   ```bash
   # Untuk debug mode
   flutter run
   
   # Untuk release mode (lebih cepat)
   flutter run --release
   ```

## 🔌 Koneksi ESP32 & Aplikasi

### Alur Komunikasi:
```
ESP32 → MQTT Broker → Flutter App
  ↑                        ↓
  └────────────────────────┘
```

### Cara Kerja:

1. **ESP32 Publish Data**:
   - Setiap 5 detik, ESP32 mengirim data suhu dan turbidity
   - ESP32 mengirim status heater (ON/OFF)

2. **Aplikasi Subscribe**:
   - Aplikasi menerima data real-time dari MQTT broker
   - Update UI secara otomatis saat data baru diterima

3. **Aplikasi Kontrol**:
   - User memilih mode di aplikasi (ON/OFF/AUTO)
   - Aplikasi publish perintah ke topic `heater/control`
   - ESP32 menerima dan mengeksekusi perintah

## 🎨 Screenshot & Tampilan

### Home Screen
- **Header**: Status koneksi & tombol refresh
- **Sensor Cards**: Menampilkan suhu dan turbidity
- **Temperature Chart**: Grafik trend suhu
- **Control Card**: Kontrol mode heater (AUTO/ON/OFF)

### Mode Heater:

#### 🔵 Mode AUTO
- ESP32 mengontrol heater otomatis
- Heater ON jika suhu < 27°C
- Heater OFF jika suhu > 30°C

#### 🟢 Mode ON
- Heater dipaksa nyala terus
- Tidak peduli suhu berapa

#### 🔴 Mode OFF
- Heater dipaksa mati
- Tidak peduli suhu berapa

## ⚠️ Troubleshooting

### 1. Aplikasi Tidak Bisa Connect ke MQTT
**Solusi**:
- Pastikan perangkat terhubung ke internet
- Coba ganti MQTT broker jika `broker.hivemq.com` down
- Tekan tombol refresh untuk reconnect

### 2. Data Sensor Tidak Muncul
**Solusi**:
- Pastikan ESP32 sudah berjalan
- Cek serial monitor ESP32 apakah publish berhasil
- Pastikan topic MQTT sama antara ESP32 dan aplikasi

### 3. Kontrol Tidak Bekerja
**Solusi**:
- Pastikan ESP32 subscribe ke topic `heater/control`
- Cek serial monitor ESP32 apakah menerima perintah
- Pastikan koneksi MQTT stabil

### 4. Grafik Tidak Muncul
**Solusi**:
- Tunggu beberapa saat sampai ada data yang masuk
- Grafik butuh minimal 2 data point untuk ditampilkan

## 🔄 Update & Konfigurasi

### Mengganti MQTT Broker

Edit file `lib/providers/mqtt_provider.dart`:
```dart
// MQTT Configuration
final String _broker = 'broker.hivemq.com';  // Ganti broker di sini
final int _port = 1883;
```

### Mengganti MQTT Topics

Edit bagian subscribe dan publish:
```dart
// Subscribe
_client.subscribe('heater/temperature', MqttQos.atLeastOnce);
_client.subscribe('heater/turbidity', MqttQos.atLeastOnce);
_client.subscribe('heater/status', MqttQos.atLeastOnce);

// Publish
_publishMessage('heater/control', message);
```

### Menyesuaikan Threshold Suhu

Edit file `lib/screens/home_screen.dart`:
```dart
Color _getTempColor(double temp) {
  if (temp < 27) return Colors.blue;    // Ganti threshold
  if (temp > 30) return Colors.red;     // Ganti threshold
  return Colors.green;
}
```

## 📊 Format Data MQTT

### Temperature
```
Topic: heater/temperature
Payload: "28.50"  # String dengan 2 desimal
```

### Turbidity
```
Topic: heater/turbidity
Payload: "1.85"  # String voltage dengan 2 desimal
```

### Heater Status
```
Topic: heater/status
Payload: "ON" / "OFF" / "AUTO" / "connected"
```

### Heater Control
```
Topic: heater/control
Payload: "ON" / "OFF" / "AUTO"
```

## 🤝 Integrasi dengan ESP32

Pastikan kode ESP32 menggunakan topic yang sama:
```cpp
// MQTT Topics (harus sama dengan aplikasi)
const char* topic_temp = "heater/temperature";
const char* topic_turbidity = "heater/turbidity";
const char* topic_status = "heater/status";
const char* topic_control = "heater/control";
```

## 📱 Build APK untuk Android

```bash
# Build APK
flutter build apk --release

# APK akan tersimpan di:
# build/app/outputs/flutter-apk/app-release.apk
```

## 🌐 Platform Support

- ✅ Android
- ✅ iOS (perlu Mac untuk build)
- ⚠️ Web (perlu konfigurasi tambahan untuk MQTT)
- ⚠️ Windows/Linux/macOS (perlu konfigurasi tambahan)

## 📝 Catatan Penting

1. **Koneksi Internet**: Aplikasi membutuhkan koneksi internet untuk terhubung ke MQTT broker
2. **ESP32 & App Harus Online Bersamaan**: Agar real-time berfungsi
3. **Public MQTT Broker**: `broker.hivemq.com` adalah broker publik, data tidak secure. Untuk production, gunakan broker private dengan authentication
4. **Battery Usage**: Aplikasi menggunakan koneksi MQTT persistent, bisa menguras baterai

## 🔒 Security Recommendation

Untuk production/deployment:
1. Gunakan MQTT broker private
2. Enable username & password authentication
3. Gunakan SSL/TLS (port 8883)
4. Jangan expose credential di kode

## 📞 Support

Jika ada pertanyaan atau masalah:
1. Cek serial monitor ESP32
2. Cek debug console Flutter
3. Test koneksi MQTT dengan tools seperti MQTT Explorer

---

**Happy Monitoring! 🐠💧🌡️**
