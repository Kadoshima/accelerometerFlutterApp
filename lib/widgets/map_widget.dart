// lib/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_provider.dart';

class MapWidget extends ConsumerStatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _path = [];

  @override
  void initState() {
    super.initState();
    // 初期位置を設定（例：東京）
    _path.add(LatLng(35.6895, 139.6917));
  }

  @override
  Widget build(BuildContext context) {
    final dataState = ref.watch(dataProvider);

    // 更新された位置情報を取得
    dataState.positions.forEach((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      _path.add(latLng);
      _markers.add(Marker(
        markerId: MarkerId(position.timestamp.toIso8601String()),
        position: latLng,
      ));
    });

    if (_path.length > 1) {
      _polylines.add(Polyline(
        polylineId: PolylineId('path'),
        points: _path,
        color: Colors.blue,
        width: 4,
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _path.last, zoom: 16),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _controller = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
