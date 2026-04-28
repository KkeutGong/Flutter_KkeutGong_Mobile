class Certificate {
  final String id;
  final String name;
  final String icon;
  // Cert-specific config used by the mock-exam screen. Default 90/60 lines up
  // with the legacy hardcoded values, so this stays safe when the backend
  // omits the fields (e.g. older API).
  final int mockExamMinutes;
  final int passScore;

  Certificate({
    required this.id,
    required this.name,
    required this.icon,
    this.mockExamMinutes = 90,
    this.passScore = 60,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      mockExamMinutes: (json['mockExamMinutes'] as num?)?.toInt() ?? 90,
      passScore: (json['passScore'] as num?)?.toInt() ?? 60,
    );
  }
}
