class EmployeeModel {
  final String id;
  final String? authId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImageUrl;
  final bool isActive;
  final String? managerId;
  final String? otpCode;
  final DateTime? otpExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? managerName;

  EmployeeModel({
    required this.id,
    this.authId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImageUrl,
    this.isActive = false,
    this.managerId,
    this.otpCode,
    this.otpExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.managerName,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  bool get isOTPExpired {
    if (otpExpiresAt == null) return true;
    return otpExpiresAt!.isBefore(DateTime.now());
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // Handle joined manager data
    String? mgrName;
    if (json['manager'] != null && json['manager'] is Map) {
      final mgr = json['manager'] as Map<String, dynamic>;
      mgrName = '${mgr['first_name'] ?? ''} ${mgr['last_name'] ?? ''}'.trim();
    }

    return EmployeeModel(
      id: json['id'] as String? ?? '',
      authId: json['auth_id'] as String?,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      managerId: json['manager_id'] as String?,
      otpCode: json['otp_code'] as String?,
      otpExpiresAt: json['otp_expires_at'] != null
          ? DateTime.parse(json['otp_expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      managerName: mgrName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'is_active': isActive,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
    };
    if (authId != null) map['auth_id'] = authId;
    if (phone != null) map['phone'] = phone;
    if (profileImageUrl != null) map['profile_image_url'] = profileImageUrl;
    if (managerId != null) map['manager_id'] = managerId;
    if (otpCode != null) map['otp_code'] = otpCode;
    if (otpExpiresAt != null) {
      map['otp_expires_at'] = otpExpiresAt!.toIso8601String();
    }
    return map;
  }

  EmployeeModel copyWith({
    String? id,
    String? authId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    bool? isActive,
    String? managerId,
    String? otpCode,
    DateTime? otpExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      managerId: managerId ?? this.managerId,
      otpCode: otpCode ?? this.otpCode,
      otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Employee($fullName, $email, active: $isActive)';
}
