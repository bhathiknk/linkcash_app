// lib/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<ConnectivityResult> checkInitialConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;
}
