import '../../../data/model/sensor_data.dart';

class BleState {
  final bool loading;
  final List<dynamic> devices;
  final SensorData? data;
  final String? error;
  final bool hasScanned;

  BleState({
    this.loading = false,
    this.hasScanned = false,

    this.devices = const [],
    this.data,
    this.error,
  });

  BleState copyWith({
    bool? loading,
    bool? hasScanned,

    List<dynamic>? devices,
    SensorData? data,
    String? error,
  }) => BleState(
    loading: loading ?? this.loading,
    devices: devices ?? this.devices,
    hasScanned: hasScanned ?? this.hasScanned,

    data: data ?? this.data,
    error: error,
  );
}
