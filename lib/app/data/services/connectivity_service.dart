import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final isOnline = false.obs;
  final connectivityResult = Rx<ConnectivityResult?>(null);
  final isManualOverride = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      connectivityResult.value = result;
      isOnline.value = _isConnected(result);
      print('📡 Connectivity initialized: ${isOnline.value ? "Online" : "Offline"}');
    } catch (e) {
      print('Error checking connectivity: $e');
      isOnline.value = false;
    }
  }

  void _listenToConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (isManualOverride.value) {
        print('📡 Connectivity change ignored (manual override is active)');
        return;
      }
      
      connectivityResult.value = result;
      final wasOnline = isOnline.value;
      final nowOnline = _isConnected(result);

      isOnline.value = nowOnline;

      if (!wasOnline && nowOnline) {
        print('📡 Connectivity changed: Offline → Online');
      } else if (wasOnline && !nowOnline) {
        print('📡 Connectivity changed: Online → Offline');
      }

      print('📡 Current status: ${nowOnline ? "Online" : "Offline"}');
    });
  }

  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  Future<bool> checkConnection() async {
    if (isManualOverride.value) {
      return isOnline.value;
    }
    
    try {
      final result = await _connectivity.checkConnectivity();
      final connected = _isConnected(result);
      isOnline.value = connected;
      return connected;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }
  
  void setManualOverride(bool online) {
    isManualOverride.value = true;
    isOnline.value = online;
    print('📡 Manual override: ${online ? "Online" : "Offline"}');
  }
  
  void clearManualOverride() {
    isManualOverride.value = false;
    _initConnectivity();
    print('📡 Manual override cleared, checking real connectivity');
  }
}

