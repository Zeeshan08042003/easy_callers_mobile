class AddScriptModel {
  bool? success;
  String? message;
  Data? data;

  AddScriptModel({this.success, this.message, this.data});

  AddScriptModel.fromJson(Map<String, dynamic> json) {
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
  String? userId;
  String? title;
  String? script;
  String? createdBy;
  String? id;
  String? updatedAt;
  String? createdAt;

  Data(
      {this.userId,
        this.title,
        this.script,
        this.createdBy,
        this.id,
        this.updatedAt,
        this.createdAt});

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    title = json['title'];
    script = json['script'];
    createdBy = json['created_by'];
    id = json['id'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['title'] = this.title;
    data['script'] = this.script;
    data['created_by'] = this.createdBy;
    data['id'] = this.id;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    return data;
  }
}
