class Records {
  int? id;
  int? userId;
  DateTime date;
  String checkIn;
  String checkOut;
  int? shiftId;
  int? lateMinutes;
  String status;
  String location;
  String remark;
  String imgName;
  String ip;

  Records({
    required this.id,
    required this.userId,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.shiftId,
    required this.lateMinutes,
    required this.status,
    required this.location,
    required this.remark,
    required this.imgName,
    required this.ip,
  });

  factory Records.fromJson(Map<String, dynamic> json) {
    return Records(
      id: json['recordId'], // Correct key for id
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      checkIn: json['checkIn'],
      checkOut: json['checkOut'],
      shiftId: json['shiftId'],
      lateMinutes: json['lateMinutes'],
      status: json['status'],
      location: json['location'],
      remark: json['remark'],
      imgName: json['imgName'],
      ip: json['ip'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': id, // Correct key for id
      'userId': userId,
      'date': date.toIso8601String().substring(0, 10),
      'checkIn': checkIn,
      'checkOut': checkOut,
      'shiftId': shiftId,
      'lateMinutes': lateMinutes,
      'status': status,
      'location': location,
      'remark': remark,
      'imgName': imgName,
      'ip': ip,
    };
  }

  // Add copyWith method to the Records class
  Records copyWith({
    int? id,
    int? userId,
    DateTime? date,
    String? checkIn,
    String? checkOut,
    int? shiftId,
    int? lateMinutes,
    String? status,
    String? location,
    String? remark,
    String? imgName,
    String? ip,
  }) {
    return Records(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      shiftId: shiftId ?? this.shiftId,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      status: status ?? this.status,
      location: location ?? this.location,
      remark: remark ?? this.remark,
      imgName: imgName ?? this.imgName,
      ip: ip ?? this.ip,
    );
  }
}
