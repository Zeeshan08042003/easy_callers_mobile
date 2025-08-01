class SubmitCallLogModel {
  bool? success;
  String? message;
  Data? data;

  SubmitCallLogModel({this.success, this.message, this.data});

  SubmitCallLogModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
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

class Data {
  String? leadId;
  String? callDuration;
  String? notes;
  String? createdBy;
  String? id;
  String? updatedAt;
  String? createdAt;

  Data(
      {this.leadId,
        this.callDuration,
        this.notes,
        this.createdBy,
        this.id,
        this.updatedAt,
        this.createdAt});

  Data.fromJson(Map<String, dynamic> json) {
    leadId = json['lead_id'];
    callDuration = json['call_duration'];
    notes = json['notes'];
    createdBy = json['created_by'];
    id = json['id'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lead_id'] = this.leadId;
    data['call_duration'] = this.callDuration;
    data['notes'] = this.notes;
    data['created_by'] = this.createdBy;
    data['id'] = this.id;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    return data;
  }
}
