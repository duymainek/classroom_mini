import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'models/cache_entry.dart';

class CacheManager {
  static const String _boxName = 'http_cache';
  static Box<CacheEntry>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CacheEntryAdapter());
    }

    _box = await Hive.openBox<CacheEntry>(_boxName);

    await clearExpiredCache();

    print('CacheManager initialized. Cached items: ${_box?.length ?? 0}');
  }

  static Box<CacheEntry> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception(
          'CacheManager not initialized. Call CacheManager.init() first');
    }
    return _box!;
  }

  static String generateKey(String path, Map<String, dynamic>? queryParams) {
    final normalizedPath = path.toLowerCase().trim();

    final sortedParams = queryParams?.entries.toList();
    sortedParams?.sort((a, b) => a.key.compareTo(b.key));

    final queryString = sortedParams
            ?.map((e) => '${e.key}=${e.value}')
            .join('&') ??
        '';

    final combined = '$normalizedPath?$queryString';

    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  static CacheEntry? get(String path, Map<String, dynamic>? queryParams) {
    try {
      final key = generateKey(path, queryParams);
      final entry = box.get(key);

      if (entry == null) return null;

      if (entry.isExpired) {
        box.delete(key);
        return null;
      }

      return entry;
    } catch (e) {
      print('Error getting cache: $e');
      return null;
    }
  }

  static Future<void> put({
    required String path,
    required Map<String, dynamic>? queryParams,
    required Map<String, dynamic> responseData,
    required int statusCode,
    required Duration ttl,
    Map<String, List<String>>? headers,
  }) async {
    try {
      final key = generateKey(path, queryParams);
      final now = DateTime.now();

      final entry = CacheEntry(
        key: key,
        path: path,
        queryParams: queryParams ?? {},
        responseData: responseData,
        statusCode: statusCode,
        cachedAt: now,
        expiresAt: now.add(ttl),
        headers: headers,
      );

      await box.put(key, entry);
      print('✅ Cached: $path (TTL: ${ttl.inMinutes}m)');
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  static Future<void> clear(String path, Map<String, dynamic>? queryParams) async {
    try {
      final key = generateKey(path, queryParams);
      await box.delete(key);
      print('🗑️ Cleared cache: $path');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  static Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (var entry in box.values) {
        if (entry.expiresAt.isBefore(now)) {
          expiredKeys.add(entry.key);
        }
      }

      if (expiredKeys.isNotEmpty) {
        await box.deleteAll(expiredKeys);
        print('🗑️ Cleared ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await box.clear();
      print('🗑️ Cleared all cache');
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }

  static Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int validCount = 0;
    int expiredCount = 0;

    for (var entry in box.values) {
      if (entry.expiresAt.isAfter(now)) {
        validCount++;
      } else {
        expiredCount++;
      }
    }

    return {
      'total': box.length,
      'valid': validCount,
      'expired': expiredCount,
    };
  }

  static Future<void> clearByPathPattern(String pattern) async {
    try {
      final keysToDelete = <String>[];

      for (var entry in box.values) {
        if (entry.path.contains(pattern)) {
          keysToDelete.add(entry.key);
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        print('🗑️ Cleared ${keysToDelete.length} cache entries matching: $pattern');
      }
    } catch (e) {
      print('Error clearing cache by pattern: $e');
    }
  }
}

