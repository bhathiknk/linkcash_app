import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<List<ConnectivityResult>> checkInitialConnectivity() async {
    // Return a list of connectivity results for all network types.
    return await _connectivity.checkConnectivity();
  }

  Stream<List<ConnectivityResult>> get connectivityStream {
    // Stream provides a list of connectivity results for all network types.
    return _connectivity.onConnectivityChanged;
  }
}
