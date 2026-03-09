import 'package:easy_callers_mobile/core/utils/enums.dart';

class LeadModel {
  final String id;
  final String name;
  final List<String> phone;
  final String? email;
  final String? location;
  final String? projectName;
  final String? projectId;
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
  final String? projectTitle; // From joined projects table

  LeadModel({
    required this.id,
    required this.name,
    this.phone = const [],
    this.email,
    this.location,
    this.projectName,
    this.projectId,
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
    this.projectTitle,
  });

  bool get isAssigned => assignedTo != null;
  bool get needsFollowUp => status == LeadStatus.followUp;
  bool get isConverted => status == LeadStatus.converted;

  /// Parse phone from database — handles String (plain or JSON-stringified array), List, or null
  static List<String> _parsePhone(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      // Handle stringified JSON array like '["9876543210","1234567890"]'
      String cleaned = value.trim();
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        // Strip outer brackets
        cleaned = cleaned.substring(1, cleaned.length - 1);
        // Split by comma and clean each entry
        return cleaned
            .split(',')
            .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
      // Plain string — might be comma-separated
      if (cleaned.contains(',')) {
        return cleaned.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [cleaned];
    }
    return [];
  }

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

    // Handle joined project data
    String? projTitle;
    if (json['projects'] != null && json['projects'] is Map) {
      final proj = json['projects'] as Map<String, dynamic>;
      projTitle = proj['name'] as String?;
    }

    return LeadModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: _parsePhone(json['phone']),
      email: json['email'] as String?,
      location: json['location'] as String?,
      projectName: json['project_name'] as String?,
      projectId: json['project_id'] as String?,
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
      projectTitle: projTitle,
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
    String? projectId,
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
    String? assignedToName,
    String? uploadedByName,
    String? projectTitle,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      projectName: projectName ?? this.projectName,
      projectId: projectId ?? this.projectId,
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
      assignedToName: assignedToName ?? this.assignedToName,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      projectTitle: projectTitle ?? this.projectTitle,
    );
  }

  @override
  String toString() => 'LeadModel($name, $phone, ${status.displayName})';
}
