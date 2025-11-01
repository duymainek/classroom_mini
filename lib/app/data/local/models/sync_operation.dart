import 'package:hive/hive.dart';

part 'sync_operation.g.dart';

@HiveType(typeId: 1)
class SyncOperation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String method;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final Map<String, dynamic>? queryParams;

  @HiveField(4)
  final Map<String, dynamic>? data;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final int retryCount;

  @HiveField(8)
  final String? errorMessage;

  @HiveField(9)
  final DateTime? lastRetryAt;

  SyncOperation({
    required this.id,
    required this.method,
    required this.path,
    this.queryParams,
    this.data,
    required this.createdAt,
    this.status = 'pending',
    this.retryCount = 0,
    this.errorMessage,
    this.lastRetryAt,
  });

  SyncOperation copyWith({
    String? id,
    String? method,
    String? path,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    String? status,
    int? retryCount,
    String? errorMessage,
    DateTime? lastRetryAt,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      method: method ?? this.method,
      path: path ?? this.path,
      queryParams: queryParams ?? this.queryParams,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get canRetry => isFailed && retryCount < 3;
}

