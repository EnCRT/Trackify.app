import '../utils/time_utils.dart';

class LapSector {
  final int? id;
  final int sessionId;
  final int lapNumber;
  final int sectorNumber; // 0 for full lap, 1+ for sectors
  final int timeMillis;
  final double distanceMeters;
  final bool isBest;

  LapSector({
    this.id,
    required this.sessionId,
    required this.lapNumber,
    required this.sectorNumber,
    required this.timeMillis,
    required this.distanceMeters,
    this.isBest = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'lapNumber': lapNumber,
      'sectorNumber': sectorNumber,
      'timeMillis': timeMillis,
      'distanceMeters': distanceMeters,
      'isBest': isBest ? 1 : 0,
    };
  }

  factory LapSector.fromMap(Map<String, dynamic> map) {
    return LapSector(
      id: map['id'],
      sessionId: map['sessionId'],
      lapNumber: map['lapNumber'],
      sectorNumber: map['sectorNumber'],
      timeMillis: map['timeMillis'],
      distanceMeters: map['distanceMeters'],
      isBest: map['isBest'] == 1,
    );
  }

  String get formattedTime => TimeUtils.formatDuration(timeMillis);
}
