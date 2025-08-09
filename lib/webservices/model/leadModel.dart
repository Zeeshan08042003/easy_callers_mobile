class LeadModel {
  bool? success;
  String? message;
  LeadData? data;

  LeadModel({this.success, this.message, this.data});

  LeadModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? LeadData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
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
      leads = [];
      json['leads'].forEach((v) {
        leads!.add(Leads.fromJson(v));
      });
    }
    currentPage = json['current_page'];
    perPage = json['per_page'];
    total = json['total'];
    lastPage = json['last_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (leads != null) {
      map['leads'] = leads!.map((v) => v.toJson()).toList();
    }
    map['current_page'] = currentPage;
    map['per_page'] = perPage;
    map['total'] = total;
    map['last_page'] = lastPage;
    return map;
  }
}

class Leads {
  String? id;
  String? sheetId;
  String? assignedTo;
  String? name;
  String? phone;
  String? email;
  String? feedback;
  LeadExtraData? data;
  String? status;
  String? assignedAt;
  String? attendedAt;
  String? createdAt;
  String? updatedAt;
  String? createdBy;
  String? updatedBy;
  String? deletedBy;
  String? deletedAt;
  String? address;
  String? meetDatetime;
  String? sheetName;
  List<CallLog>? callLogs;

  Leads({
    this.id,
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
    this.address,
    this.meetDatetime,
    this.sheetName,
    this.callLogs,
  });

  Leads.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sheetId = json['sheet_id'];
    assignedTo = json['assigned_to'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    feedback = json['feedback'];

    if (json['data'] is String) {
      data = null; // avoid error if API sends a string
    } else {
      data = json['data'] != null ? LeadExtraData.fromJson(json['data']) : null;
    }

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
    meetDatetime = json['meet_datetime'];
    sheetName = json['sheet_name'];

    if (json['call_logs'] != null) {
      callLogs = [];
      json['call_logs'].forEach((v) {
        callLogs!.add(CallLog.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['id'] = id;
    map['sheet_id'] = sheetId;
    map['assigned_to'] = assignedTo;
    map['name'] = name;
    map['phone'] = phone;
    map['email'] = email;
    map['feedback'] = feedback;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    map['status'] = status;
    map['assigned_at'] = assignedAt;
    map['attended_at'] = attendedAt;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['created_by'] = createdBy;
    map['updated_by'] = updatedBy;
    map['deleted_by'] = deletedBy;
    map['deleted_at'] = deletedAt;
    map['address'] = address;
    map['meet_datetime'] = meetDatetime;
    map['sheet_name'] = sheetName;
    if (callLogs != null) {
      map['call_logs'] = callLogs!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class LeadExtraData {
  int? srNo;
  String? name;
  int? no;

  LeadExtraData({this.srNo, this.name, this.no});

  LeadExtraData.fromJson(Map<String, dynamic> json) {
    srNo = json['sr no'];
    name = json['name'];
    no = json['no'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['sr no'] = srNo;
    map['name'] = name;
    map['no'] = no;
    return map;
  }
}

class CallLog {
  String? id;
  String? leadId;
  int? callDuration;
  String? notes;
  String? createdAt;
  String? updatedAt;
  String? createdBy;
  String? updatedBy;
  String? deletedBy;
  String? deletedAt;
  String? status;

  CallLog({
    this.id,
    this.leadId,
    this.callDuration,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    this.status,
  });

  CallLog.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    leadId = json['lead_id'];
    callDuration = json['call_duration'];
    notes = json['notes'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    deletedBy = json['deleted_by'];
    deletedAt = json['deleted_at'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['id'] = id;
    map['lead_id'] = leadId;
    map['call_duration'] = callDuration;
    map['notes'] = notes;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['created_by'] = createdBy;
    map['updated_by'] = updatedBy;
    map['deleted_by'] = deletedBy;
    map['deleted_at'] = deletedAt;
    map['status'] = status;
    return map;
  }
}
