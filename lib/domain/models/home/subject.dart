class Subject {
  final String id;
  final String name;
  final bool isCompleted;

  Subject({
    required this.id,
    required this.name,
    required this.isCompleted,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}
