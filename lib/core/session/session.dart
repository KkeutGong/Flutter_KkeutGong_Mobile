class Session {
  Session._internal();
  static final Session _instance = Session._internal();
  factory Session() => _instance;

  // Empty until a successful login populates it. Don't read this for API
  // requests — the backend uses the JWT subject instead.
  String userId = '';
  String currentCertificateId = '1';

  bool get isAuthenticated => userId.isNotEmpty;

  final Map<String, String> _subjectIdByName = {};

  void rememberSubjects(Iterable<({String id, String name})> subjects) {
    _subjectIdByName.clear();
    for (final s in subjects) {
      _subjectIdByName[s.name] = s.id;
    }
  }

  String? subjectIdFor(String name) => _subjectIdByName[name];
}
