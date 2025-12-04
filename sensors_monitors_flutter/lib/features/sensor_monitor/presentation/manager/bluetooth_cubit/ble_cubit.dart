import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../data/repo/sensor_monitor_repo.dart';
import 'ble_state.dart';

class BleCubit extends Cubit<BleState> {
  final BleRepo repo;

  BleCubit(this.repo) : super(BleState());

  Future<void> scan() async {
    emit(state.copyWith(loading: true));

    final result = await repo.scanDevices();
    result.fold(
      (failure) => emit(state.copyWith(error: failure.error, loading: false)),
      (devices) => emit(state.copyWith(devices: devices, loading: false)),
    );
  }

  Future<void> connect(BluetoothDevice device) async {
    final result = await repo.connectAndListen(device);

    result.fold((failure) => emit(state.copyWith(error: failure.error)), (
      stream,
    ) {
      stream.listen((data) {
        emit(state.copyWith(data: data));
      });
    });
  }
}
