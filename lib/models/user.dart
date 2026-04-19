class User {
  final int? id;
  final String nickname;
  final String firstName;
  final String lastName;
  final DateTime joinDate;

  User({
    this.id,
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.joinDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'firstName': firstName,
      'lastName': lastName,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nickname: map['nickname'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      joinDate: DateTime.parse(map['joinDate']),
    );
  }

  String get fullName => '$firstName $lastName';
}
