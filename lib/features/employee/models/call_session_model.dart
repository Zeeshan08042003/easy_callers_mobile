import 'package:flutter/material.dart';

class CallSession {
  final String number;
  final String duration; // format: HH:mm:ss
  final String status;   // completed, missed, failed, etc.
  final DateTime? callTime;

  CallSession({
    required this.number,
    required this.duration,
    required this.status,
    this.callTime,
  });

  /// Factory for Android JSON
  factory CallSession.fromJson(Map<String, dynamic> json) {
    final dynamic rawDuration = json['duration'];

    String formattedDuration = "00:00:00";

    if (rawDuration is int) {
      // Convert seconds to HH:mm:ss
      final duration = Duration(seconds: rawDuration);
      formattedDuration = duration.toString().split('.').first.padLeft(8, "0");
    } else if (rawDuration is String) {
      formattedDuration = rawDuration;
    }

    return CallSession(
      number: json['number']?.toString() ?? '',
      duration: formattedDuration,
      status: json['status']?.toString() ?? '',
      callTime: json['time'] != null
          ? DateTime.tryParse(json['time'].toString())
          : null,
    );
  }


  /// iOS factory (since iOS gives duration separately)
  factory CallSession.fromIos({
    required String number,
    required String duration,
    String status = "completed",
  }) {
    return CallSession(
      number: number,
      duration: duration,
      status: status,
      callTime: DateTime.now(),
    );
  }

  /// Convert duration to seconds
  int get durationInSeconds {
    if (duration.isEmpty) return 0;

    final parts = duration.split(':');
    if (parts.length != 3) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return hours * 3600 + minutes * 60 + seconds;
  }

  /// Check if call connected
  bool get isConnected {
    return status.toLowerCase() == "completed" ||
        status.toLowerCase() == "connected";
  }

  /// Human readable status
  String get readableStatus {
    if (isConnected) {
      return "Connected";
    } else {
      return "Not Connected";
    }
  }

  /// Status color
  Color get statusColor {
    return isConnected
        ? Colors.green
        : Colors.red;
  }

  /// Background color
  Color get statusBackgroundColor {
    return isConnected
        ? Colors.green.withOpacity(.1)
        : Colors.red.withOpacity(.1);
  }
}
