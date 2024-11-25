import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  DateTime time;
  
  @HiveField(2)
  bool isEnabled;

  @HiveField(3)
  String message;

  Alarm({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.message = 'Time\'s Up!',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'isEnabled': isEnabled,
      'message': message,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      time: DateTime.parse(map['time']),
      isEnabled: map['isEnabled'],
      message: map['message'] ?? 'Time\'s Up!',
    );
  }
} 