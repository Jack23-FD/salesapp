import 'package:flutter/foundation.dart';

enum UserRole {
  staff,
  admin,
}

class User {
  final String id;
  final String email;
  final String name;
  final String? companyName;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String authProvider;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.companyName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    required this.authProvider,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      companyName: map['companyName'],
      phoneNumber: map['phoneNumber'],
      role: _parseRole(map['role']),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      lastLogin: map['lastLogin']?.toDate() ?? DateTime.now(),
      authProvider: map['authProvider'] ?? 'email',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'role': describeEnum(role),
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'authProvider': authProvider,
    };
  }

  static UserRole _parseRole(String? roleStr) {
    if (roleStr == null || roleStr.isEmpty) {
      print('User.parseRole: Role string is null or empty, defaulting to staff');
      return UserRole.staff;
    }
    
    // Normalize the role string by removing any whitespace and converting to lowercase
    final normalizedRole = roleStr.trim().toLowerCase();
    
    print('User.parseRole: Parsing role string: "$roleStr" (normalized: "$normalizedRole")');
    
    if (normalizedRole == 'admin') {
      print('User.parseRole: Parsed as admin role');
      return UserRole.admin;
    }
    
    print('User.parseRole: Parsed as staff role (default)');
    return UserRole.staff; // Default to staff
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? companyName,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? authProvider,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  
  // For backward compatibility
  String get displayName => name;

  // Define equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: ${describeEnum(role)}, isAdmin: $isAdmin)';
  }
}

// Helper function to convert enum to string
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
} 