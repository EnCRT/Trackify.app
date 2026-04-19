class User {
  final int? id;
  final String nickname;
  final String firstName;
  final String lastName;
  final DateTime joinDate;
  final double totalDistanceMeters;
  final int totalTimeMillis;
  final int sessionsCount;

  User({
    this.id,
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.joinDate,
    this.totalDistanceMeters = 0,
    this.totalTimeMillis = 0,
    this.sessionsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'firstName': firstName,
      'lastName': lastName,
      'joinDate': joinDate.toIso8601String(),
      'totalDistanceMeters': totalDistanceMeters,
      'totalTimeMillis': totalTimeMillis,
      'sessionsCount': sessionsCount,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nickname: map['nickname'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      joinDate: DateTime.parse(map['joinDate']),
      totalDistanceMeters: (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      totalTimeMillis: (map['totalTimeMillis'] as int?) ?? 0,
      sessionsCount: (map['sessionsCount'] as int?) ?? 0,
    );
  }

  String get fullName => '$firstName $lastName';
}
