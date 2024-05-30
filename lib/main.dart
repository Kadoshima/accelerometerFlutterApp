import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accelerometer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Accelerometer Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Map<String, dynamic>> _sensorData = [];
  late StreamSubscription<AccelerometerEvent> _subscription;
  late Directory _directory;
  bool _isRecording = false;
  String _currentData = 'x: 0, y: 0, z: 0';
  late DateTime _startTime;
  late Timer _samplingTimer;
  late Timer _fileTimer;
  double _currentX = 0;
  double _currentY = 0;
  double _currentZ = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      await _initializeDirectory();
    } else {
      print('Storage permission denied');
    }
  }

  Future<void> _initializeDirectory() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final path = Directory('${directory.path}/Csv');
        if (!await path.exists()) {
          await path.create(recursive: true);
        }
        _directory = path;
        print('Directory path: ${_directory.path}');
      } else {
        print('Could not get external storage directory');
      }
    } catch (e) {
      print('Error initializing directory: $e');
    }
  }

  void _startSensor() {
    _startTime = DateTime.now();
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _currentX = event.x;
        _currentY = event.y;
        _currentZ = event.z;
        _currentData = 'x: $_currentX, y: $_currentY, z: $_currentZ';
      });
    });

    // 10msごとにデータをサンプリング
    _samplingTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      final now = DateTime.now();
      final data = {
        'timestamp': now.millisecondsSinceEpoch,
        'x': _currentX,
        'y': _currentY,
        'z': _currentZ,
      };
      setState(() {
        _sensorData.add(data);
      });
    });

    _fileTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!_isRecording) {
        timer.cancel();
      } else {
        await _saveData();
        _sensorData.clear();
      }
    });
  }

  Future<void> _saveData() async {
    final fileName = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${_directory.path}/$fileName.csv');
    try {
      final sink = file.openWrite();
      sink.write('timestamp,x,y,z\n');
      for (var entry in _sensorData) {
        sink.write(
            '${entry['timestamp']},${entry['x']},${entry['y']},${entry['z']}\n');
      }
      await sink.flush();
      await sink.close();
      print('Data saved to ${file.path}');
    } catch (e) {
      print('Error writing to file: $e');
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _subscription.cancel();
      _samplingTimer.cancel();
      _fileTimer.cancel();
    } else {
      _startSensor();
    }
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  @override
  void dispose() {
    if (_isRecording) {
      _subscription.cancel();
      _samplingTimer.cancel();
      _fileTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_isRecording ? 'Stop' : 'Start'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(height: 20),
            Text(
              _currentData,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
