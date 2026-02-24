class ManagerModel {
  final String id;
  final String? authId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImageUrl;
  final bool isActive;
  final int? maxEmployees;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBySuperAdminId;
  final bool isSaVisible;
  final String? agencyName;


  // Computed / joined data
  final int? employeeCount;

  ManagerModel({
    required this.id,
    this.authId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImageUrl,
    this.isActive = true,
    this.maxEmployees,
    required this.createdAt,
    required this.updatedAt,
    this.createdBySuperAdminId,
    this.isSaVisible = false,
    this.agencyName,
    this.employeeCount,
  });



  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  factory ManagerModel.fromJson(Map<String, dynamic> json) {
    return ManagerModel(
      id: json['id'] as String,
      authId: json['auth_id'] as String?,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      maxEmployees: json['max_employees'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
      createdBySuperAdminId: json['created_by_super_admin_id'] as String?,
      isSaVisible: json['is_sa_visible'] as bool? ?? false,
      agencyName: json['agency_name'] as String?,
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
      'max_employees': maxEmployees,
      'created_by_super_admin_id': createdBySuperAdminId,
      'is_sa_visible': isSaVisible,
      'agency_name': agencyName,
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
    if (maxEmployees != null) map['max_employees'] = maxEmployees;
    if (createdBySuperAdminId != null) map['created_by_super_admin_id'] = createdBySuperAdminId;
    map['is_sa_visible'] = isSaVisible;
    if (agencyName != null) map['agency_name'] = agencyName;
    return map;
  }



  ManagerModel copyWith({
    String? id,
    String? authId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    bool? isActive,
    int? maxEmployees,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBySuperAdminId,
    bool? isSaVisible,
    String? agencyName,
    int? employeeCount,
  }) {
    return ManagerModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      maxEmployees: maxEmployees ?? this.maxEmployees,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBySuperAdminId: createdBySuperAdminId ?? this.createdBySuperAdminId,
      isSaVisible: isSaVisible ?? this.isSaVisible,
      agencyName: agencyName ?? this.agencyName,
      employeeCount: employeeCount ?? this.employeeCount,
    );
  }



  @override
  String toString() => 'Manager($fullName, $email)';
}
