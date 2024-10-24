// lib/utils/csv_helper.dart
import 'package:csv/csv.dart';
import '../models/sensor_data.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CSVHelper {
  /// センサーデータリストをCSV形式の文字列に変換します。
  static String generateCSV(List<SensorData> dataList) {
    List<List<dynamic>> rows = [
      ['timestamp', 'x', 'y', 'z', '心拍数', '緯度', '経度']
    ];

    for (var data in dataList) {
      rows.add([
        data.timestamp.toIso8601String(),
        data.x,
        data.y,
        data.z,
        data.heartRate,
        data.latitude,
        data.longitude,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// CSVデータをデバイスのローカルストレージに保存します。
  /// 保存先のパスを返します。
  static Future<String> saveCSV(String csvData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${directory.path}/sensor_data_$timestamp.csv';
    final file = File(path);
    await file.writeAsString(csvData);
    return path;
  }
}
