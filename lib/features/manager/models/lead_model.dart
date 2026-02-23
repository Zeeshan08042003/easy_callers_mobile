import 'package:easy_callers_mobile/core/utils/enums.dart';

class LeadModel {
  final String id;
  final String name;
  final List<String> phone;
  final String? email;
  final String? location;
  final String? projectName;
  final String? budget;
  final String? source;
  final String? notes;
  final LeadStatus status;
  final String? uploadedBy;
  final String? assignedTo;
  final String? batchId;
  final Map<String, dynamic>? extraData; // Extra columns from uploaded files
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (optional, populated when querying with joins)
  final String? assignedToName;
  final String? uploadedByName;

  LeadModel({
    required this.id,
    required this.name,
    this.phone = const [],
    this.email,
    this.location,
    this.projectName,
    this.budget,
    this.source,
    this.notes,
    this.status = LeadStatus.newLead,
    this.uploadedBy,
    this.assignedTo,
    this.batchId,
    this.extraData,
    required this.createdAt,
    required this.updatedAt,
    this.assignedToName,
    this.uploadedByName,
  });

  bool get isAssigned => assignedTo != null;
  bool get needsFollowUp => status == LeadStatus.followUp;
  bool get isConverted => status == LeadStatus.converted;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // Handle joined data from separate tables (managers, employees)
    String? assignedName;
    if (json['employees'] != null && json['employees'] is Map) {
      final user = json['employees'] as Map<String, dynamic>;
      assignedName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    } else if (json['assigned_to_user'] != null && json['assigned_to_user'] is Map) {
      // Compatibility for custom aliases in queries
      final user = json['assigned_to_user'] as Map<String, dynamic>;
      assignedName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    }

    String? uploadedName;
    if (json['managers'] != null && json['managers'] is Map) {
      final user = json['managers'] as Map<String, dynamic>;
      uploadedName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    } else if (json['uploaded_by_user'] != null && json['uploaded_by_user'] is Map) {
      final user = json['uploaded_by_user'] as Map<String, dynamic>;
      uploadedName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    }

    return LeadModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as List?)?.map((e) => e.toString()).toList() ?? [],
      email: json['email'] as String?,
      location: json['location'] as String?,
      projectName: json['project_name'] as String?,
      budget: json['budget'] as String?,
      source: json['source'] as String?,
      notes: json['notes'] as String?,
      status: LeadStatus.fromString(json['status'] as String? ?? 'new'),
      uploadedBy: json['uploaded_by'] as String?,
      assignedTo: json['assigned_to'] as String?,
      batchId: json['batch_id'] as String?,
      extraData: json['extra_data'] != null
          ? Map<String, dynamic>.from(json['extra_data'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedToName: assignedName,
      uploadedByName: uploadedName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'project_name': projectName,
      'budget': budget,
      'source': source,
      'notes': notes,
      'status': status.value,
      'uploaded_by': uploadedBy,
      'assigned_to': assignedTo,
      'batch_id': batchId,
      'extra_data': extraData,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'status': status.value,
    };
    if (email != null) map['email'] = email;
    if (location != null) map['location'] = location;
    if (projectName != null) map['project_name'] = projectName;
    if (budget != null) map['budget'] = budget;
    if (source != null) map['source'] = source;
    if (notes != null) map['notes'] = notes;
    if (uploadedBy != null) map['uploaded_by'] = uploadedBy;
    if (assignedTo != null) map['assigned_to'] = assignedTo;
    if (batchId != null) map['batch_id'] = batchId;
    if (extraData != null && extraData!.isNotEmpty) map['extra_data'] = extraData;
    return map;
  }

  LeadModel copyWith({
    String? id,
    String? name,
    List<String>? phone,
    String? email,
    String? location,
    String? projectName,
    String? budget,
    String? source,
    String? notes,
    LeadStatus? status,
    String? uploadedBy,
    String? assignedTo,
    String? batchId,
    Map<String, dynamic>? extraData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      projectName: projectName ?? this.projectName,
      budget: budget ?? this.budget,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      batchId: batchId ?? this.batchId,
      extraData: extraData ?? this.extraData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'LeadModel($name, $phone, ${status.displayName})';
}
