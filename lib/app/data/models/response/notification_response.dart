import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:classroom_mini/app/data/models/response/base_response.dart';

part 'notification_response.g.dart';

@JsonSerializable()
class NotificationResponse extends BaseResponse {
  final NotificationData? data;

  NotificationResponse({
    required super.success,
    super.message,
    super.code,
    super.errors,
    this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
}

@JsonSerializable()
class NotificationData {
  final List<NotificationModel>? notifications;
  final NotificationModel? notification;
  final int? total;
  final int? limit;
  final int? offset;
  final int? unreadCount;
  final int? deletedCount;
  final int? updatedCount;

  const NotificationData({
    this.notifications,
    this.notification,
    this.total,
    this.limit,
    this.offset,
    this.unreadCount,
    this.deletedCount,
    this.updatedCount,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      _$NotificationDataFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDataToJson(this);
}

@JsonSerializable()
class NotificationModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  String get typeIcon {
    switch (type) {
      case 'assignment':
        return '📝';
      case 'quiz':
        return '📋';
      case 'quiz_submission':
        return '📝';
      case 'announcement':
        return '📢';
      case 'announcement_comment':
        return '💬';
      case 'grade':
        return '✅';
      case 'material':
        return '📚';
      case 'deadline':
        return '⏰';
      case 'general':
        return '💬';
      default:
        return '🔔';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'assignment':
        return Colors.blue;
      case 'quiz':
        return Colors.purple;
      case 'quiz_submission':
        return Colors.purple;
      case 'announcement':
        return Colors.orange;
      case 'announcement_comment':
        return Colors.orange;
      case 'grade':
        return Colors.green;
      case 'material':
        return Colors.teal;
      case 'deadline':
        return Colors.red;
      case 'general':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String? get actionUrl {
    return data?['action_url'] as String?;
  }
}
