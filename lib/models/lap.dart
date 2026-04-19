import '../utils/time_utils.dart';

class SectorData {
  final int sectorIndex;
  final int durationMillis;
  final int crossingPointIndex; // Index in the session's routePoints

  SectorData({
    required this.sectorIndex,
    required this.durationMillis,
    required this.crossingPointIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'sectorIndex': sectorIndex,
      'durationMillis': durationMillis,
      'crossingPointIndex': crossingPointIndex,
    };
  }

  factory SectorData.fromMap(Map<String, dynamic> map) {
    return SectorData(
      sectorIndex: map['sectorIndex'],
      durationMillis: map['durationMillis'],
      crossingPointIndex: map['crossingPointIndex'],
    );
  }
}

class Lap {
  final int number;
  final int durationMillis;
  final int startPointIndex;
  final int endPointIndex;
  final List<SectorData> sectors;

  Lap({
    required this.number,
    required this.durationMillis,
    required this.startPointIndex,
    required this.endPointIndex,
    required this.sectors,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'durationMillis': durationMillis,
      'startPointIndex': startPointIndex,
      'endPointIndex': endPointIndex,
      'sectors': sectors.map((s) => s.toMap()).toList(),
    };
  }

  factory Lap.fromMap(Map<String, dynamic> map) {
    return Lap(
      number: map['number'],
      durationMillis: map['durationMillis'],
      startPointIndex: map['startPointIndex'],
      endPointIndex: map['endPointIndex'],
      sectors: (map['sectors'] as List)
          .map((s) => SectorData.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedDuration => TimeUtils.formatDuration(durationMillis);
}
