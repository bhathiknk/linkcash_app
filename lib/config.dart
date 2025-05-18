// lib/config.dart

/// Toggle this to `true` when using the emulator,
/// or `false` when testing on a real device.
bool useEmulator = true;

final String baseEmulatorUrl = 'http://10.0.2.2:8080';
final String baseRealDeviceUrl = 'http://192.168.1.101:8080';

String get baseUrl => useEmulator ? baseEmulatorUrl : baseRealDeviceUrl;

