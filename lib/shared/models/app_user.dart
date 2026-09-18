import 'enums.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.role,
    required this.points,
    this.email = '',
    this.district = '',
    this.language = 'fr',
    this.notificationsEnabled = true,
    this.avatarFileId,
    this.level = 'bronze',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String city;
  final String district;
  final UserRole role;
  final int points;
  final String language;
  final bool notificationsEnabled;
  final String? avatarFileId;
  final String level;

  factory AppUser.fromMap(Map<String, dynamic> map, {required String id}) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      city: map['city'] as String? ?? 'Yaoundé',
      district: map['district'] as String? ?? '',
      role: UserRoleX.parse(map['role'] as String?),
      points: (map['points'] as num?)?.toInt() ?? 0,
      language: map['language'] as String? ?? 'fr',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      avatarFileId: map['avatarFileId'] as String?,
      level: map['level'] as String? ?? 'bronze',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'city': city,
        'district': district,
        'role': role.wire,
        'points': points,
        'language': language,
        'notificationsEnabled': notificationsEnabled,
        'avatarFileId': avatarFileId,
        'level': level,
      };

  AppUser copyWith({
    String? name,
    String? email,
    String? city,
    String? district,
    UserRole? role,
    int? points,
    String? language,
    bool? notificationsEnabled,
    String? level,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone,
      email: email ?? this.email,
      city: city ?? this.city,
      district: district ?? this.district,
      role: role ?? this.role,
      points: points ?? this.points,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      avatarFileId: avatarFileId,
      level: level ?? this.level,
    );
  }

  String get levelLabel {
    if (points >= 3000) return 'Or';
    if (points >= 1000) return 'Argent';
    return 'Bronze';
  }
}
