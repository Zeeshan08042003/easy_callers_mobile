class LeadBatchModel {
  final String id;
  final String fileName;
  final String? fileUrl;
  final int totalLeads;
  final String? uploadedBy;
  final DateTime createdAt;

  // Joined data
  final String? uploadedByName;

  LeadBatchModel({
    required this.id,
    required this.fileName,
    this.fileUrl,
    this.totalLeads = 0,
    this.uploadedBy,
    required this.createdAt,
    this.uploadedByName,
  });

  factory LeadBatchModel.fromJson(Map<String, dynamic> json) {
    String? uploaderName;
    if (json['managers'] != null && json['managers'] is Map) {
      final user = json['managers'] as Map<String, dynamic>;
      uploaderName =
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    } else if (json['uploaded_by_user'] != null && json['uploaded_by_user'] is Map) {
      final user = json['uploaded_by_user'] as Map<String, dynamic>;
      uploaderName =
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    }

    return LeadBatchModel(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String?,
      totalLeads: json['total_leads'] as int? ?? 0,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      uploadedByName: uploaderName,
    );
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'file_name': fileName,
      'total_leads': totalLeads,
    };
    if (fileUrl != null) map['file_url'] = fileUrl;
    if (uploadedBy != null) map['uploaded_by'] = uploadedBy;
    return map;
  }

  @override
  String toString() => 'LeadBatchModel($fileName, $totalLeads leads)';
}
