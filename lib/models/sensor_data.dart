// lib/models/sensor_data.dart
class SensorData {
  DateTime timestamp;
  double x;
  double y;
  double z;
  int heartRate;
  double latitude;
  double longitude;

  SensorData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required this.heartRate,
    required this.latitude,
    required this.longitude,
  });
}
