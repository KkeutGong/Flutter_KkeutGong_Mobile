class Certificate {
  final String id;
  final String name;
  final String icon;

  Certificate({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }
}
