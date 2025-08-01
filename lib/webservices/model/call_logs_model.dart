class CallLogModel {
  String? number;
  String? type;
  String? status;
  String? time;
  String? duration;

  CallLogModel({this.number, this.type, this.status, this.time, this.duration});

  CallLogModel.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    type = json['type'];
    status = json['status'];
    time = json['time'];
    duration = json['duration'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['number'] = this.number;
    data['type'] = this.type;
    data['status'] = this.status;
    data['time'] = this.time;
    data['duration'] = this.duration;
    return data;
  }
}
