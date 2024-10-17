import 'package:flutter/material.dart';

class Task {
  final int taskId;
  final String title;
  final TimeOfDay time;
  final Color color;
  final int day;
  final int month;
  final int year;
  final int userId;
  final Duration? reminderDuration;

  Task({
    required this.taskId,
    required this.title,
    required this.time,
    required this.color,
    required this.day,
    required this.month,
    required this.year,
    required this.userId,
    this.reminderDuration,
  });

  // Factory constructor from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    Duration? reminderDuration;
    if (json['reminderDuration'] != null) {
      reminderDuration = Duration(seconds: json['reminderDuration']);
    }

    return Task(
      taskId: json['taskId'],
      title: json['title'],
      time:
          TimeOfDay(hour: json['time']['hour'], minute: json['time']['minute']),
      color: _colorFromJson(json['color']),
      day: json['day'],
      month: json['month'],
      year: json['year'],
      userId: json['userId'],
      reminderDuration: reminderDuration,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'time': {'hour': time.hour, 'minute': time.minute},
      'color': color.value.toString(),
      'day': day,
      'month': month,
      'year': year,
      'userId': userId,
      'reminderDuration': reminderDuration?.inSeconds,
    };
  }

  static Color _colorFromJson(String colorString) {
    return Color(int.parse(colorString));
  }
}
