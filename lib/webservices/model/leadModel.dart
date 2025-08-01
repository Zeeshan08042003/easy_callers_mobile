class LeadModel {
  bool? success;
  String? message;
  LeadData? data;

  LeadModel({this.success, this.message, this.data});

  LeadModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new LeadData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class LeadData {
  List<Leads>? leads;
  int? currentPage;
  int? perPage;
  int? total;
  int? lastPage;

  LeadData({this.leads, this.currentPage, this.perPage, this.total, this.lastPage});

  LeadData.fromJson(Map<String, dynamic> json) {
    if (json['leads'] != null) {
      leads = <Leads>[];
      json['leads'].forEach((v) {
        leads!.add(new Leads.fromJson(v));
      });
    }
    currentPage = json['current_page'];
    perPage = json['per_page'];
    total = json['total'];
    lastPage = json['last_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.leads != null) {
      data['leads'] = this.leads!.map((v) => v.toJson()).toList();
    }
    data['current_page'] = this.currentPage;
    data['per_page'] = this.perPage;
    data['total'] = this.total;
    data['last_page'] = this.lastPage;
    return data;
  }
}

class Leads {
  String? id;
  String? sheetId;
  String? assignedTo;
  String? name;
  String? phone;
  String? email;
  dynamic feedback;
  String? data;
  String? status;
  String? assignedAt;
  dynamic attendedAt;
  String? createdAt;
  String? updatedAt;
  String? createdBy;
  dynamic updatedBy;
  dynamic deletedBy;
  dynamic deletedAt;
  dynamic address;

  Leads(
      {this.id,
        this.sheetId,
        this.assignedTo,
        this.name,
        this.phone,
        this.email,
        this.feedback,
        this.data,
        this.status,
        this.assignedAt,
        this.attendedAt,
        this.createdAt,
        this.updatedAt,
        this.createdBy,
        this.updatedBy,
        this.deletedBy,
        this.deletedAt,
        this.address});

  Leads.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sheetId = json['sheet_id'];
    assignedTo = json['assigned_to'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    feedback = json['feedback'];
    data = json['data'];
    status = json['status'];
    assignedAt = json['assigned_at'];
    attendedAt = json['attended_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    deletedBy = json['deleted_by'];
    deletedAt = json['deleted_at'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sheet_id'] = this.sheetId;
    data['assigned_to'] = this.assignedTo;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['email'] = this.email;
    data['feedback'] = this.feedback;
    data['data'] = this.data;
    data['status'] = this.status;
    data['assigned_at'] = this.assignedAt;
    data['attended_at'] = this.attendedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['deleted_by'] = this.deletedBy;
    data['deleted_at'] = this.deletedAt;
    data['address'] = this.address;
    return data;
  }
}
