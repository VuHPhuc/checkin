import 'package:flutter/material.dart';

class Task {
  final String title;
  final TimeOfDay time;
  final Color color;
  final int day;
  final int month;
  final int year;
  final int userId;

  Task({
    required this.title,
    required this.time,
    required this.color,
    required this.day,
    required this.month,
    required this.year,
    required this.userId,
  });

  // Add a factory constructor to create a Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      time:
          TimeOfDay(hour: json['time']['hour'], minute: json['time']['minute']),
      color: Color(
          int.parse(json['color'].substring(6, 14), radix: 16) + 0xFF000000),
      day: json['day'],
      month: json['month'],
      year: json['year'],
      userId: json['userId'],
    );
  }

  // Add a method to convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': {'hour': time.hour, 'minute': time.minute},
      'color': '#${color.value.toRadixString(16).substring(2, 10)}',
      'day': day,
      'month': month,
      'year': year,
      'userId': userId,
    };
  }
}
