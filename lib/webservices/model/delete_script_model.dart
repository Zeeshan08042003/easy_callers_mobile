class DeleteScriptModel {
  bool? success;
  String? message;
  List<dynamic>? data; // Use dynamic since delete API might return empty list

  DeleteScriptModel({this.success, this.message, this.data});

  DeleteScriptModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    result['success'] = success;
    result['message'] = message;
    result['data'] = data;
    return result;
  }
}


class MessageModel {
  bool? success;
  String? message;
  List<dynamic>? data; // Use dynamic since delete API might return empty list

  MessageModel({this.success, this.message, this.data});

  MessageModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    result['success'] = success;
    result['message'] = message;
    result['data'] = data;
    return result;
  }
}
