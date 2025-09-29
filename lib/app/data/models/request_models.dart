/// Request models for API communication
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}

class CreateStudentRequest {
  final String username;
  final String password;
  final String email;
  final String fullName;

  CreateStudentRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
    };
  }

  factory CreateStudentRequest.fromJson(Map<String, dynamic> json) {
    return CreateStudentRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
    );
  }
}

class UpdateStudentRequest {
  final String? email;
  final String? fullName;
  final bool? isActive;

  UpdateStudentRequest({
    this.email,
    this.fullName,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (fullName != null) data['fullName'] = fullName;
    if (isActive != null) data['isActive'] = isActive;
    return data;
  }

  factory UpdateStudentRequest.fromJson(Map<String, dynamic> json) {
    return UpdateStudentRequest(
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      isActive: json['isActive'] as bool?,
    );
  }
}

class BulkOperationRequest {
  final List<String> studentIds;
  final String action;
  final Map<String, dynamic>? data;

  BulkOperationRequest({
    required this.studentIds,
    required this.action,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentIds': studentIds,
      'action': action,
      if (data != null) 'data': data,
    };
  }

  factory BulkOperationRequest.fromJson(Map<String, dynamic> json) {
    return BulkOperationRequest(
      studentIds: List<String>.from(json['studentIds'] as List),
      action: json['action'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class ResetPasswordRequest {
  final String newPassword;

  ResetPasswordRequest({
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'newPassword': newPassword,
    };
  }

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) {
    return ResetPasswordRequest(
      newPassword: json['newPassword'] as String,
    );
  }
}

class ImportStudentsRequest {
  final List<Map<String, dynamic>> records;
  final String? idempotencyKey;

  ImportStudentsRequest({
    required this.records,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'records': records,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }

  factory ImportStudentsRequest.fromJson(Map<String, dynamic> json) {
    return ImportStudentsRequest(
      records: List<Map<String, dynamic>>.from(json['records'] as List),
      idempotencyKey: json['idempotencyKey'] as String?,
    );
  }
}

class UpdateProfileRequest {
  final String? email;
  final String? avatarUrl;

  UpdateProfileRequest({
    this.email,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    return data;
  }

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) {
    return UpdateProfileRequest(
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
