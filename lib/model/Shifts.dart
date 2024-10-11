class Shift {
  int shiftId;
  String shiftName;
  Duration startTime;
  Duration endTime;
  String? description;

  Shift({
    required this.shiftId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      shiftId: json['shiftId'],
      shiftName: json['shiftName'],
      startTime: Duration(seconds: json['startTime']),
      endTime: Duration(seconds: json['endTime']),
      description: json['description'],
    );
  }
}
