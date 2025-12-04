class SensorData {
  final double light;
  final double smoke;

  SensorData({required this.light, required this.smoke});
  Map<String, dynamic> toJson() => {'lightValue': light, 'smokeValue': smoke};
}
