import 'dart:ffi';

class LoginModel {
  bool? success;
  String? token;
  Data? data;
  String? message;

  LoginModel({this.success, this.token, this.data, this.message});

  LoginModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    token = json['token'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['token'] = this.token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = this.message;
    return data;
  }
}

class Data {
  User? user;
  Company? company;

  Data({this.user,this.company});

  Data.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    company = json['company'] != null ? new Company.fromJson(json['company']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.user != null) {
      data['user'] = this.user!.toJson();
      data['company'] = this.company!.toJson();
    }
    return data;
  }
}

class User {
  String? id;
  String? companyId;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  dynamic? emailVerifiedAt;
  bool? isActive;
  dynamic? lastLoginAt;
  String? role;
  String? createdAt;
  String? updatedAt;
  dynamic? createdBy;
  dynamic? updatedBy;
  dynamic? deletedAt;
  Company? company;

  User(
      {this.id,
        this.companyId,
        this.firstName,
        this.lastName,
        this.email,
        this.phone,
        this.emailVerifiedAt,
        this.isActive,
        this.lastLoginAt,
        this.role,
        this.createdAt,
        this.updatedAt,
        this.createdBy,
        this.updatedBy,
        this.deletedAt,
        this.company});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    companyId = json['company_id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    phone = json['phone'];
    emailVerifiedAt = json['email_verified_at'];
    isActive = json['is_active'];
    lastLoginAt = json['last_login_at'];
    role = json['role'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    deletedAt = json['deleted_at'];
    company =
    json['company'] != null ? new Company.fromJson(json['company']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['company_id'] = this.companyId;
    data['first_name'] = this.firstName;
    data['last_name'] = this.lastName;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['email_verified_at'] = this.emailVerifiedAt;
    data['is_active'] = this.isActive;
    data['last_login_at'] = this.lastLoginAt;
    data['role'] = this.role;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['deleted_at'] = this.deletedAt;
    if (this.company != null) {
      data['company'] = this.company!.toJson();
    }
    return data;
  }
}

class Company {
  String? id;
  String? name;
  dynamic? industry;
  dynamic? phone;
  dynamic? email;
  dynamic? address;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  String? createdBy;
  String? updatedBy;
  dynamic? deletedBy;
  dynamic? deletedAt;

  Company(
      {this.id,
        this.name,
        this.industry,
        this.phone,
        this.email,
        this.address,
        this.isActive,
        this.createdAt,
        this.updatedAt,
        this.createdBy,
        this.updatedBy,
        this.deletedBy,
        this.deletedAt});

  Company.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    industry = json['industry'];
    phone = json['phone'];
    email = json['email'];
    address = json['address'];
    isActive = json['is_active'];
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
    data['name'] = this.name;
    data['industry'] = this.industry;
    data['phone'] = this.phone;
    data['email'] = this.email;
    data['address'] = this.address;
    data['is_active'] = this.isActive;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['deleted_by'] = this.deletedBy;
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}
