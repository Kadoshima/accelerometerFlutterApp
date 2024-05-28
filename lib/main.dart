import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

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
  final List<String> _sensorData = [];
  late StreamSubscription _subscription;
  late File _file;
  bool _isSensorAvailable = false;
  bool _isRecording = false;
  String _currentData = 'x: 0, y: 0, z: 0';

  @override
  void initState() {
    super.initState();
    _initializeFile();
    _checkSensorAvailability();
  }

  Future<void> _initializeFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    _file = File('$path/accelerometer_data.csv');
    await _file.writeAsString('timestamp,x,y,z\n');
  }

  Future<void> _checkSensorAvailability() async {
    final sensorAvailable = await SensorManager().isSensorAvailable(Sensors.ACCELEROMETER);
    setState(() {
      _isSensorAvailable = sensorAvailable;
    });
  }

  void _startSensor() async {
    final sensor = await SensorManager().sensorUpdates(
      sensorId: Sensors.ACCELEROMETER,
      interval: Duration(microseconds: Duration.microsecondsPerSecond ~/ 200),
    );

    _subscription = sensor.listen((event) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final x = event.data[0];
      final y = event.data[1];
      final z = event.data[2];
      final data = '$timestamp,$x,$y,$z\n';

      setState(() {
        _currentData = 'x: $x, y: $y, z: $z';
        _sensorData.add(data);
      });

      _saveData(data);
    });
  }

  Future<void> _saveData(String data) async {
    await _file.writeAsString(data, mode: FileMode.append);
  }

  void _toggleRecording() {
    if (_isRecording) {
      _subscription.cancel();
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
              onPressed: _isSensorAvailable ? _toggleRecording : null,
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
