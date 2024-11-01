import 'package:flutter/material.dart';

class Task {
  final int taskId;
  final int userId;
  final String title;
  final DateTime time;
  final DateTime remindTime;
  final Color color;

  Task({
    required this.taskId,
    required this.userId,
    required this.title,
    required this.time,
    required this.remindTime,
    required this.color,
  });

  // Factory constructor from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'],
      userId: json['userId'],
      title: json['title'],
      time: DateTime.parse(json['time']),
      remindTime: DateTime.parse(json['remindTime']),
      color: _colorFromJson(json['color']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'userId': userId,
      'title': title,
      'time': time.toIso8601String(),
      'remindTime': remindTime.toIso8601String(),
      'color': color.value.toString(),
    };
  }

  static Color _colorFromJson(String colorString) {
    return Color(int.parse(colorString));
  }
}
