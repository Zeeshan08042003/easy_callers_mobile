class GetScriptModel {
  bool? success;
  String? message;
  Data? data;

  GetScriptModel({this.success, this.message, this.data});

  GetScriptModel.fromJson(Map<String, dynamic> json) {
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
  List<Scripts>? scripts;

  Data({this.scripts});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['scripts'] != null) {
      scripts = <Scripts>[];
      json['scripts'].forEach((v) {
        scripts!.add(new Scripts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.scripts != null) {
      data['scripts'] = this.scripts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Scripts {
  String? id;
  String? userId;
  String? title;
  String? script;
  String? createdAt;
  String? updatedAt;
  String? createdBy;
  Null? updatedBy;
  Null? deletedBy;
  Null? deletedAt;

  Scripts(
      {this.id,
        this.userId,
        this.title,
        this.script,
        this.createdAt,
        this.updatedAt,
        this.createdBy,
        this.updatedBy,
        this.deletedBy,
        this.deletedAt});

  Scripts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    title = json['title'];
    script = json['script'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    deletedBy = json['deleted_by'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['title'] = this.title;
    data['script'] = this.script;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['deleted_by'] = this.deletedBy;
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}
