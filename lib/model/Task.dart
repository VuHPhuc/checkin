class Task {
  int? id;
  int? userId;
  String? title;
  String? note;
  int? isCompleted;
  String? date;
  String? startTime;
  String? endTime;
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
    this.remind,
    this.repeat,
  });

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? note,
    int? isCompleted,
    String? date,
    String? startTime,
    String? endTime,
    int? remind,
    String? repeat,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      remind: remind ?? this.remind,
      repeat: repeat ?? this.repeat,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        note: json['note'],
        isCompleted: json['isCompleted'],
        date: json['date'],
        startTime: json['startTime'],
        endTime: json['endTime'],
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
        'remind': remind,
        'repeat': repeat,
      };
}
