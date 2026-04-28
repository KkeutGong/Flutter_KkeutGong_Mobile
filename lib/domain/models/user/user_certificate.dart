class UserCertificate {
  final String certificateId;
  final String name;
  final String icon;
  final bool isActive;
  final DateTime addedAt;

  UserCertificate({
    required this.certificateId,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.addedAt,
  });

  factory UserCertificate.fromJson(Map<String, dynamic> json) {
    return UserCertificate(
      certificateId: json['certificateId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      isActive: json['isActive'] as bool,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }
}
