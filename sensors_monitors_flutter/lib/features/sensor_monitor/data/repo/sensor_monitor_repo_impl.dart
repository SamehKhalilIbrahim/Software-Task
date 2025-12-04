// ble_repo_impl.dart
import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../model/sensor_data.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/bluetooth_service.dart';
import 'sensor_monitor_repo.dart';

class BleRepoImpl implements BleRepo {
  final BleService service;

  BleRepoImpl(this.service);

  @override
  Future<Either<Failure, List<ScanResult>>> scanDevices() {
    return guard(() async {
      final stream = service.scan();
      return await stream.first;
    });
  }

  @override
  Future<Either<Failure, Stream<SensorData>>> connectAndListen(
    BluetoothDevice device,
  ) {
    return guard(() async {
      final char = await service.connect(device);
      if (char == null) throw "Characteristic not found";

      char.setNotifyValue(true);

      return char.lastValueStream.map((raw) {
        final parsed = service.parse(utf8.decode(raw));
        service.postDataToAPI(
          SensorData(light: parsed["light"]!, smoke: parsed["smoke"]!),
        );
        return SensorData(light: parsed["light"]!, smoke: parsed["smoke"]!);
      });
    });
  }
}
