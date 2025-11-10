import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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
      debugPrint(
          '📡 Connectivity initialized: ${isOnline.value ? "Online" : "Offline"}');
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      isOnline.value = false;
    }
  }

  void _listenToConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (isManualOverride.value) {
        debugPrint(
            '📡 Connectivity change ignored (manual override is active)');
        return;
      }

      connectivityResult.value = result;
      final wasOnline = isOnline.value;
      final nowOnline = _isConnected(result);

      isOnline.value = nowOnline;

      if (!wasOnline && nowOnline) {
        debugPrint('📡 Connectivity changed: Offline → Online');
      } else if (wasOnline && !nowOnline) {
        debugPrint('📡 Connectivity changed: Online → Offline');
      }

      debugPrint('📡 Current status: ${nowOnline ? "Online" : "Offline"}');
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
      debugPrint('Error checking connection: $e');
      return false;
    }
  }

  void setManualOverride(bool online) {
    isManualOverride.value = true;
    isOnline.value = online;
    debugPrint('📡 Manual override: ${online ? "Online" : "Offline"}');
  }

  void clearManualOverride() {
    isManualOverride.value = false;
    _initConnectivity();
    debugPrint('📡 Manual override cleared, checking real connectivity');
  }
}
