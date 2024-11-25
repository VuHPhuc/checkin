import 'package:flutter/material.dart';

class Task {
  final String taskId; // Use String for taskId, preferably UUID
  final String title;
  final DateTime startTime; // Use DateTime for start and end times
  final DateTime endTime;
  final int remindBefore; // Reminder time in milliseconds
  final int userId;
  Color? color; // Make color optional and nullable

  Task({
    required this.taskId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.remindBefore,
    required this.userId,
    this.color,
  });

  // Factory constructor from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'],
      title: json['title'],
      startTime: DateTime.parse(json['startTime']), // Parse startTime
      endTime: DateTime.parse(json['endTime']), // Parse endTime
      remindBefore: json['remindBefore'],
      userId: json['userId'],
      color: json['color'] != null
          ? Color(int.parse(json['color']))
          : null, // Parse color if present
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'startTime': startTime.toIso8601String(), // Convert to ISO 8601 string
      'endTime': endTime.toIso8601String(), // Convert to ISO 8601 string
      'remindBefore': remindBefore,
      'userId': userId,
      'color': color?.value.toString(), // Convert color to string if present
    };
  }

  // Method to calculate and update the color based on remindBefore
  void updateColor() {
    final now = DateTime.now();
    final timeDifference = startTime.difference(now).inMilliseconds;

    if (timeDifference <= Duration(hours: 1).inMilliseconds) {
      color = Colors.red;
    } else if (timeDifference <= Duration(days: 1).inMilliseconds) {
      color = Colors.orange; // Or another color closer to red
    } else if (timeDifference <= Duration(days: 2).inMilliseconds) {
      color = Colors.yellow;
    } else if (timeDifference <= Duration(days: 4).inMilliseconds) {
      color = Colors.green;
    } else {
      color = null; // Or a default color
    }
  }
}
