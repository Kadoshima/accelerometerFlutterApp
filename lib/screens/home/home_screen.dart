// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_provider.dart';
import '../../widgets/map_widget.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataProvider);
    final dataNotifier = ref.read(dataProvider.notifier);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authNotifier.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MapWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '心拍数: ${dataState.currentHeartRate} BPM',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: dataState.isCollecting
                    ? null
                    : () {
                        dataNotifier.startCollection();
                      },
                child: Text('Start'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: dataState.isCollecting
                    ? () async {
                        await dataNotifier.stopCollection();
                        // アップロードのフィードバックを表示
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('データをアップロードしました。'),
                        ));
                      }
                    : null,
                child: Text('Stop'),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
