class Task {
  int? id;
  int? userId;
  String? title;
  String? note;
  int? isCompleted;
  String? date;
  String? startTime;
  String? endTime;
  int? color;
  int? remind;
  String? repeat;

  Task({
    this.id,
    this.userId,
    this.title,
    this.note,
    this.isCompleted,
    this.date,
    this.startTime,
    this.endTime,
    this.color,
    this.remind,
    this.repeat,
  });

  // fromJson and toJson for converting to/from maps
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        note: json['note'],
        isCompleted: json['isCompleted'],
        date: json['date'],
        startTime: json['startTime'],
        endTime: json['endTime'],
        color: json['color'],
        remind: json['remind'],
        repeat: json['repeat'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'note': note,
        'isCompleted': isCompleted,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'color': color,
        'remind': remind,
        'repeat': repeat,
      };
}
