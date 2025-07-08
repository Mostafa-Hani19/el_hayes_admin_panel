import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastSignIn;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.lastSignIn,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('UserModel.fromJson: Raw JSON: $json');
    
    // Determine role based on is_admin field
    String role = 'user';
    if (json.containsKey('is_admin') && json['is_admin'] == true) {
      role = 'admin';
    } else if (json.containsKey('role')) {
      role = json['role'];
    }
    
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      role: role,
      createdAt: DateTime.parse(json['created_at']),
      lastSignIn: json['last_sign_in'] != null 
        ? DateTime.parse(json['last_sign_in']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in': lastSignIn?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }
} 