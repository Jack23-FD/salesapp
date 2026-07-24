// User Model

enum UserRole {
  staff,
  admin,
}

class User {
  final String id;
  final String email;
  final String name;
  final String? username;
  final String? bio;
  final String? profilePictureUrl;
  final String? address;
  final String? companyName;
  final String? phoneNumber;
  final String? staffId;
  final String? branch;
  final String? roleTitle;
  final UserRole role;
  final String status;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String authProvider;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.username,
    this.bio,
    this.profilePictureUrl,
    this.address,
    this.companyName,
    this.phoneNumber,
    this.staffId,
    this.branch,
    this.roleTitle,
    required this.role,
    this.status = 'active',
    required this.createdAt,
    required this.lastLogin,
    required this.authProvider,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    try {
      return value.toDate();
    } catch (_) {
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? map['user_name'],
      bio: map['bio'],
      profilePictureUrl: map['profilePictureUrl'] ?? map['profile_picture_url'] ?? map['avatar'],
      address: map['address'],
      companyName: map['companyName'],
      phoneNumber: map['phoneNumber'] ?? map['phone'],
      staffId: map['staffId'] ?? map['staff_id'],
      branch: map['branch'],
      roleTitle: map['roleTitle'] ?? map['role_title'],
      role: _parseRole(map['role']),
      status: map['status'] ?? 'active',
      createdAt: _parseDateTime(map['createdAt']),
      lastLogin: _parseDateTime(map['lastLogin']),
      authProvider: map['authProvider'] ?? 'email',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'bio': bio,
      'profilePictureUrl': profilePictureUrl,
      'address': address,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'staffId': staffId,
      'branch': branch,
      'roleTitle': roleTitle,
      'role': describeEnum(role),
      'status': status,
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
    String? username,
    String? bio,
    String? profilePictureUrl,
    String? address,
    String? companyName,
    String? phoneNumber,
    String? staffId,
    String? branch,
    String? roleTitle,
    UserRole? role,
    String? status,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? authProvider,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      address: address ?? this.address,
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      staffId: staffId ?? this.staffId,
      branch: branch ?? this.branch,
      roleTitle: roleTitle ?? this.roleTitle,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status.toLowerCase() == 'active';
  bool get isDisabled => status.toLowerCase() == 'disabled' || status.toLowerCase() == 'inactive';
  
  // Helpers for Staff Profile display
  String get displayStaffId {
    if (staffId != null && staffId!.isNotEmpty) return staffId!;
    final numClean = id.replaceAll(RegExp(r'[^0-9]'), '');
    final paddedNum = numClean.isEmpty ? '00024' : numClean.padLeft(5, '0');
    return 'STF-${paddedNum.length > 5 ? paddedNum.substring(paddedNum.length - 5) : paddedNum}';
  }

  String get displayBranch => (branch != null && branch!.isNotEmpty) ? branch! : (companyName ?? 'Chennai Main Branch');
  String get displayRoleTitle => (roleTitle != null && roleTitle!.isNotEmpty) ? roleTitle! : (isAdmin ? 'Administrator' : 'Sales Executive');
  String get displayPhone => (phoneNumber != null && phoneNumber!.trim().isNotEmpty) ? phoneNumber!.trim() : '+91 98765 43210';

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