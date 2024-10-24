// lib/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';

class MapWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataProvider);

    // マーカーの生成
    final Set<Marker> markers = dataState.positions
        .map((position) => Marker(
              markerId: MarkerId(position.timestamp.toIso8601String()),
              position: LatLng(position.latitude, position.longitude),
            ))
        .toSet();

    // パスの生成
    final List<LatLng> path = dataState.positions
        .map((position) => LatLng(position.latitude, position.longitude))
        .toList();

    // ポリラインの生成
    final Set<Polyline> polylines = {
      if (path.length > 1)
        Polyline(
          polylineId: PolylineId('path'),
          points: path,
          color: Colors.blue,
          width: 4,
        )
    };

    // カメラの初期位置
    final CameraPosition initialCameraPosition = CameraPosition(
      target:
          path.isNotEmpty ? path.last : LatLng(35.6895, 139.6917), // デフォルトは東京
      zoom: 16,
    );

    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        // 必要に応じてコントローラーを保持
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
