import 'package:hive/hive.dart';

part 'cache_entry.g.dart';

@HiveType(typeId: 0)
class CacheEntry {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final Map<String, dynamic> queryParams;

  @HiveField(3)
  final Map<String, dynamic> responseData;

  @HiveField(4)
  final int statusCode;

  @HiveField(5)
  final DateTime cachedAt;

  @HiveField(6)
  final DateTime expiresAt;

  @HiveField(7)
  final Map<String, List<String>>? headers;

  CacheEntry({
    required this.key,
    required this.path,
    required this.queryParams,
    required this.responseData,
    required this.statusCode,
    required this.cachedAt,
    required this.expiresAt,
    this.headers,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  bool get isExpired => !isValid;

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}

