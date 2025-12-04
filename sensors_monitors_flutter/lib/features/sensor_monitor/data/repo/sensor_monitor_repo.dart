// ble_repo.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/errors/failures.dart';
import '../model/sensor_data.dart';

abstract class BleRepo {
  Future<Either<Failure, Stream<SensorData>>> connectAndListen(
    BluetoothDevice device,
  );
  Future<Either<Failure, List<dynamic>>> scanDevices();
}
