import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl(Connectivity());
});

abstract class ConnectivityService {
  Future<bool> get isConnected;
  Stream<List<ConnectivityResult>> get cleanupStream;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityServiceImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    // In newer connectivity_plus versions, checkConnectivity returns a List<ConnectivityResult> 
    // or we might need to check if the result contains none.
    // However, looking at version 6.1.4, checkConnectivity returns List<ConnectivityResult>.
    // Wait, let me verify connectivity_plus 6.x API.
    // It returns List<ConnectivityResult> in 6.0.0+.
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<List<ConnectivityResult>> get cleanupStream => 
      _connectivity.onConnectivityChanged;
}
