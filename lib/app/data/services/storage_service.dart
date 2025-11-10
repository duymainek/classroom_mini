import 'dart:convert';
import 'package:classroom_mini/app/data/models/response/user_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._internal();
    _preferences ??= await SharedPreferences.getInstance();
    debugPrint(
        '[StorageService] SharedPreferences instance initialized. Hash: ${_preferences.hashCode}');
    return _instance!;
  }

  StorageService._internal();

  // Token management
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    debugPrint(
        '[StorageService] Saving tokens with key: ${StorageKeys.accessToken}. Prefs Hash: ${_preferences.hashCode}');
    await _preferences!.setString(StorageKeys.accessToken, accessToken);
    await _preferences!.setString(StorageKeys.refreshToken, refreshToken);
    await _preferences!.setBool(StorageKeys.isLoggedIn, true);
    debugPrint(
        '[StorageService] Tokens saved. AccessToken: ${accessToken.substring(0, 10)}..., RefreshToken: ${refreshToken.substring(0, 10)}...');
    // Save dummy value for persistence test
    await _preferences!.setString('dummy_test_key', 'test_value_persisted');
  }

  Future<String?> getAccessToken() async {
    debugPrint(
        '[StorageService] Retrieving AccessToken with key: ${StorageKeys.accessToken}. Prefs Hash: ${_preferences.hashCode}');
    final token = _preferences!.getString(StorageKeys.accessToken);
    debugPrint(
        '[StorageService] Retrieving AccessToken. Found: ${token != null ? "Yes" : "No"}');
    return token;
  }

  Future<String?> getRefreshToken() async {
    return _preferences!.getString(StorageKeys.refreshToken);
  }

  Future<void> clearTokens() async {
    debugPrint('[StorageService] Clearing tokens...');
    await _preferences!.remove(StorageKeys.accessToken);
    await _preferences!.remove(StorageKeys.refreshToken);
    await _preferences!.setBool(StorageKeys.isLoggedIn, false);
    debugPrint('[StorageService] Tokens cleared.');
  }

  // User data management
  Future<void> saveUserData(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _preferences!.setString(StorageKeys.userData, userJson);
  }

  Future<UserModel?> getUserData() async {
    final userJson = _preferences!.getString(StorageKeys.userData);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      // If there's an error parsing, clear the corrupted data
      await clearUserData();
      return null;
    }
  }

  Future<void> clearUserData() async {
    await _preferences!.remove(StorageKeys.userData);
  }

  // Login status
  Future<bool> isLoggedIn() async {
    return _preferences!.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    debugPrint('[StorageService] Clearing all data...');
    await clearTokens();
    await clearUserData();
    debugPrint('[StorageService] All data cleared.');
  }

  // Generic storage methods
  Future<void> setString(String key, String value) async {
    await _preferences!.setString(key, value);
  }

  Future<String?> getString(String key) async {
    return _preferences!.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences!.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    return _preferences!.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _preferences!.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    return _preferences!.getInt(key);
  }

  Future<void> remove(String key) async {
    await _preferences!.remove(key);
  }

  Future<bool> containsKey(String key) async {
    return _preferences!.containsKey(key);
  }
}
