# Panduan Kalibrasi dan NTU Turbidity

## ✅ Fitur yang Telah Ditambahkan

### 1. **Kalibrasi Suhu (Temperature Calibration)**
   - Menambahkan fungsi untuk mengkalibrasi sensor suhu DS18B20
   - Format MQTT: `CAL:25.5` (dikirim ke topic `heater/calibrate`)
   - Mendukung reset kalibrasi dengan command `RESET`

### 2. **Turbidity dalam NTU**
   - Mengubah satuan turbidity dari Voltage (V) ke NTU (Nephelometric Turbidity Units)
   - Range nilai: 0-3000 NTU
   - Kode warna berdasarkan tingkat kekeruhan:
     - 🟢 Hijau (0-50 NTU): Air bersih
     - 🟢 Hijau muda (50-100 NTU): Sedikit keruh
     - 🟠 Orange (100-200 NTU): Keruh
     - 🔴 Merah (>200 NTU): Sangat keruh

---

## 📱 Cara Menggunakan Kalibrasi di Aplikasi

### **Langkah-langkah Kalibrasi:**

1. **Koneksi ke MQTT Broker**
   - Pastikan ESP32 dan aplikasi terhubung ke broker MQTT
   - Cek status koneksi di bagian atas aplikasi

2. **Persiapan Kalibrasi**
   - Siapkan termometer referensi yang sudah dikalibrasi
   - Ukur suhu aktual air menggunakan termometer referensi
   - Catat nilai suhu yang terukur (misalnya: 25.5°C)

3. **Melakukan Kalibrasi**
   - Scroll ke bagian "Calibration" di aplikasi
   - Tekan tombol **"Calibrate"**
   - Dialog akan muncul menampilkan:
     - Suhu yang terbaca saat ini oleh sensor
     - Input field untuk suhu referensi
   - Masukkan nilai suhu dari termometer referensi (15-40°C)
   - Tekan tombol **"Calibrate"**

4. **Verifikasi**
   - Aplikasi akan mengirim command `CAL:25.5` ke ESP32
   - ESP32 akan menghitung offset dan menyimpannya
   - Suhu yang ditampilkan akan disesuaikan dengan nilai referensi

5. **Reset Kalibrasi**
   - Jika ingin menghapus kalibrasi, tekan tombol **"Reset"**
   - Offset akan dikembalikan ke 0.0°C

---

## 🔧 Implementasi di Kode

### **MQTT Provider (lib/providers/mqtt_provider.dart)**

```dart
// Variabel kalibrasi
double _tempOffset = 0.0;
double get tempOffset => _tempOffset;

// Fungsi kirim kalibrasi
void calibrateTemperature(double referenceTemp) {
  if (_isConnected) {
    final message = 'CAL:$referenceTemp';
    _publishMessage('heater/calibrate', message);
    debugPrint('📡 Sending calibration: $message');
  }
}

// Fungsi reset kalibrasi
void resetCalibration() {
  if (_isConnected) {
    _publishMessage('heater/calibrate', 'RESET');
    _tempOffset = 0.0;
    notifyListeners();
  }
}

// Parsing response dari ESP32
case 'heater/calibrate':
  debugPrint('📊 Calibration response: $payload');
  // ESP32 akan mengirim konfirmasi atau offset
  if (payload.startsWith('OFFSET:')) {
    _tempOffset = double.parse(payload.substring(7));
    notifyListeners();
  }
  break;
```

### **Home Screen (lib/screens/home_screen.dart)**

```dart
// Card untuk kalibrasi
Card(
  child: Column(
    children: [
      Text('Temperature Calibration'),
      Text('Offset: ${mqtt.tempOffset.toStringAsFixed(2)}°C'),
      Row(
        children: [
          ElevatedButton(
            onPressed: () => _showCalibrationDialog(context, mqtt),
            child: Text('Calibrate'),
          ),
          ElevatedButton(
            onPressed: () => mqtt.resetCalibration(),
            child: Text('Reset'),
          ),
        ],
      ),
    ],
  ),
)

// Dialog input suhu referensi
void _showCalibrationDialog(BuildContext context, MqttProvider mqtt) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Temperature Calibration'),
      content: TextField(
        decoration: InputDecoration(
          labelText: 'Reference Temperature',
          suffixText: '°C',
        ),
      ),
      actions: [
        TextButton(child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            mqtt.calibrateTemperature(refTemp);
            Navigator.pop(context);
          },
          child: Text('Calibrate'),
        ),
      ],
    ),
  );
}
```

---

## 📊 Turbidity NTU

### **Perubahan dari Voltage ke NTU:**

**Sebelum:**
```dart
double _turbidity = 2.5;  // Dalam Volt
String unit = 'V';
```

**Sesudah:**
```dart
double _turbidityNTU = 150.0;  // Dalam NTU
String unit = 'NTU';
```

### **Demo Data NTU:**
```dart
// Simulasi turbidity 100-300 NTU
_turbidityNTU = 100.0 + (DateTime.now().second % 20) * 10.0;
```

### **Warna Indikator:**
```dart
Color _getTurbidityColor(double turbidity) {
  if (turbidity < 50) return Colors.green;       // Bersih
  if (turbidity < 100) return Colors.lightGreen; // Sedikit keruh
  if (turbidity < 200) return Colors.orange;     // Keruh
  return Colors.red;                              // Sangat keruh
}
```

---

## 🔄 MQTT Topics

| Topic | Direction | Format | Deskripsi |
|-------|-----------|--------|-----------|
| `heater/temperature` | ESP32 → App | `27.5` | Suhu dalam °C |
| `heater/turbidity` | ESP32 → App | `150.0` | Turbidity dalam NTU |
| `heater/status` | ESP32 → App | `ON/OFF` | Status heater |
| `heater/control` | App → ESP32 | `AUTO/ON/OFF` | Mode heater |
| `heater/calibrate` | App → ESP32 | `CAL:25.5` atau `RESET` | Kalibrasi suhu |
| `heater/calibrate` | ESP32 → App | `OFFSET:0.5` | Konfirmasi offset |

---

## 🧪 Testing

### **Test Kalibrasi:**
1. Jalankan aplikasi dan ESP32
2. Catat suhu yang ditampilkan (misalnya: 27.8°C)
3. Ukur dengan termometer referensi (misalnya: 26.5°C)
4. Lakukan kalibrasi dengan nilai 26.5
5. Verifikasi suhu berubah menjadi 26.5°C
6. Offset yang tersimpan: -1.3°C

### **Test Turbidity NTU:**
1. Masukkan sensor ke air bersih → NTU rendah (hijau)
2. Tambahkan bubuk ke air → NTU naik (orange/merah)
3. Verifikasi warna indikator berubah sesuai nilai

---

## 📝 Notes

- **Range Kalibrasi:** 15-40°C (disesuaikan dengan kebutuhan akuarium)
- **Akurasi NTU:** Tergantung kualitas sensor turbidity
- **Penyimpanan Offset:** Offset disimpan di variabel (belum di EEPROM)
- **Real-time Update:** Semua data update otomatis via MQTT

---

## 🚀 Build APK

Untuk membuat APK dengan fitur kalibrasi dan NTU:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

APK akan tersimpan di:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📞 Support

Jika ada masalah atau pertanyaan:
1. Cek koneksi MQTT broker
2. Verifikasi ESP32 subscribe ke topic `heater/calibrate`
3. Lihat debug log di aplikasi untuk message MQTT
4. Pastikan format message sesuai: `CAL:25.5` atau `RESET`

**Selamat menggunakan fitur kalibrasi dan turbidity NTU! 🎉**
