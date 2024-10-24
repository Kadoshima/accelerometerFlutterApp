// lib/providers/data_provider.dart
import 'dart:async';
import 'dart:io' show Platform; // Platform クラスをインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';
import '../services/upload_service.dart';
import '../utils/csv_helper.dart'; // CSVHelper を正しくインポート
import 'auth_provider.dart';
import '../response/login_response.dart';

class DataState {
  final bool isCollecting;
  final List<SensorData> sensorDataList;
  final int currentHeartRate;
  final List<Position> positions;

  DataState({
    required this.isCollecting,
    required this.sensorDataList,
    required this.currentHeartRate,
    required this.positions,
  });

  factory DataState.initial() {
    return DataState(
      isCollecting: false,
      sensorDataList: [],
      currentHeartRate: 0,
      positions: [],
    );
  }

  DataState copyWith({
    bool? isCollecting,
    List<SensorData>? sensorDataList,
    int? currentHeartRate,
    List<Position>? positions,
  }) {
    return DataState(
      isCollecting: isCollecting ?? this.isCollecting,
      sensorDataList: sensorDataList ?? this.sensorDataList,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      positions: positions ?? this.positions,
    );
  }
}

class DataNotifier extends StateNotifier<DataState> {
  final UploadService _uploadService;
  final Ref _ref; // Riverpod 2.x では Ref を使用
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<int>? _heartRateSubscription; // ウェアラブルからの心拍数取得

  DataNotifier(this._ref, this._uploadService) : super(DataState.initial());

  void startCollection() async {
    // 位置情報の取得
    LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 1), // 1秒ごとに更新
        // 他のAndroid特有の設定があればここに追加
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        // 他のiOS特有の設定があればここに追加
      );
    } else {
      // その他のプラットフォーム用のデフォルト設定
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      state = state.copyWith(
        positions: [...state.positions, position],
      );
    });

    // 加速度センサの取得
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final sensorData = SensorData(
        timestamp: DateTime.now().toUtc(),
        x: event.x,
        y: event.y,
        z: event.z,
        heartRate: state.currentHeartRate,
        latitude:
            state.positions.isNotEmpty ? state.positions.last.latitude : 0.0,
        longitude:
            state.positions.isNotEmpty ? state.positions.last.longitude : 0.0,
      );
      state = state.copyWith(
        sensorDataList: [...state.sensorDataList, sensorData],
      );
    });

    // 心拍数の取得（例：ウェアラブルデバイスからのデータ）
    // 実際にはBluetooth接続などが必要ですが、ここではダミーデータを使用
    _heartRateSubscription = Stream.periodic(Duration(seconds: 1), (count) {
      // ダミーデータとしてランダムな心拍数を生成
      return 60 + (count % 40);
    }).listen((heartRate) {
      state = state.copyWith(currentHeartRate: heartRate);
      if (state.sensorDataList.isNotEmpty) {
        // 最後のセンサーデータの心拍数を更新
        final lastData = state.sensorDataList.last;
        final updatedData = SensorData(
          timestamp: lastData.timestamp,
          x: lastData.x,
          y: lastData.y,
          z: lastData.z,
          heartRate: heartRate,
          latitude: lastData.latitude,
          longitude: lastData.longitude,
        );
        final updatedList = List<SensorData>.from(state.sensorDataList)
          ..removeLast()
          ..add(updatedData);
        state = state.copyWith(sensorDataList: updatedList);
      }
    });

    state = state.copyWith(isCollecting: true);
  }

  Future<void> stopCollection() async {
    await _positionSubscription?.cancel();
    await _accelerometerSubscription?.cancel();
    await _heartRateSubscription?.cancel();

    state = state.copyWith(isCollecting: false);

    // CSV生成と保存
    final csvData = CSVHelper.generateCSV(state.sensorDataList);
    final csvPath = await CSVHelper.saveCSV(csvData);
    print('CSVデータを保存しました: $csvPath');

    // AWSへのアップロード
    final authState = _ref.read(authProvider);
    if (authState.accessToken != null) {
      try {
        await _uploadService.uploadCSV(csvData, authState.accessToken!);
        print('AWSへのアップロードに成功しました。');
      } catch (e) {
        // アップロード失敗時のエラーハンドリング
        // 例: 再試行、ユーザーへの通知など
        print('データのアップロードに失敗しました: $e');
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _heartRateSubscription?.cancel();
    super.dispose();
  }

  /// 位置情報のパーミッションをリクエストします。
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 位置情報サービスが有効か確認
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 位置情報サービスが無効の場合、ユーザーに有効化を促す
      print('位置情報サービスが無効です。設定を確認してください。');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // パーミッションが拒否された場合
        print('位置情報のパーミッションが拒否されました。');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // パーミッションが永遠に拒否された場合
      print('位置情報のパーミッションが永遠に拒否されました。設定を確認してください。');
      return false;
    }

    return true;
  }
}

// プロバイダーの定義
final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService();
});

final dataProvider = StateNotifierProvider<DataNotifier, DataState>((ref) {
  final uploadService = ref.read(uploadServiceProvider);
  return DataNotifier(ref, uploadService);
});
