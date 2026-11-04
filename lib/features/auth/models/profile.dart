class Profile {
  const Profile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.avatarPath,
  });

  factory Profile.fromJson(Map<String, Object?> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    avatarPath: json['avatar_path'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  final String id;
  final String? displayName;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;
}
