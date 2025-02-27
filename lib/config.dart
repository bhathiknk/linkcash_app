// lib/config.dart

/// Toggle this to `true` when using the emulator,
/// or `false` when testing on a real device.
bool useEmulator = true;

final String baseEmulatorUrl = 'http://10.0.2.2:8080';
final String baseRealDeviceUrl = 'http://192.168.1.100:8080';
// Replace with your actual LAN IP, e.g. 192.168.1.100

String get baseUrl => useEmulator ? baseEmulatorUrl : baseRealDeviceUrl;
