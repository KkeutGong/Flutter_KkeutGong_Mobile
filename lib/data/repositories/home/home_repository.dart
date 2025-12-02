import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';
import 'package:kkeutgong_mobile/data/repositories/study/study_progress_repository.dart';

class HomeRepository {
  static final HomeRepository _instance = HomeRepository._internal();
  factory HomeRepository() => _instance;
  HomeRepository._internal();

  String _currentCertificateId = '1';
  
  HomeData? _cache;
  DateTime? _cacheTimestamp;
  String? _cachedCertificateId;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_cache == null || _cacheTimestamp == null || _cachedCertificateId == null) {
      return false;
    }
    if (_cachedCertificateId != _currentCertificateId) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry;
  }

  Future<HomeData> getHomeData({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cache!;
    }

    final today = DateTime.now();
    final daysFromSunday = today.weekday % 7;
    final startOfWeek = today.subtract(Duration(days: daysFromSunday));
    final recentDays = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final completedWithinLastTwoDays = !date.isAfter(today) && today.difference(date).inDays <= 2;
      return {
        'date': date.toIso8601String(),
        'isCompleted': completedWithinLastTwoDays,
      };
    });
    final currentStreak = recentDays.where((day) => day['isCompleted'] as bool).length;

    final certificateData = _getCertificateData(_currentCertificateId);

    final progressRepo = StudyProgressRepository();
    
    // 현재 자격증의 첫 번째 subject에 대한 진행률 로드
    final subjects = certificateData['subjects'] as List;
    String? activeSubjectName;
    for (final s in subjects) {
      if (s['isCompleted'] != true) {
        activeSubjectName = s['name'] as String?;
        break;
      }
    }
    
    double conceptProgress = 0.0;
    double practiceProgress = 0.0;
    
    if (activeSubjectName != null) {
      conceptProgress = await progressRepo.getConceptPercent(activeSubjectName);
      practiceProgress = await progressRepo.getPracticePercent(activeSubjectName);
    }
    
    // 전체 진행률 계산 (모든 subject 기준)
    final subjectNames = subjects.map((s) => s['name'] as String).toList();
    final overallProgress = await progressRepo.calculateOverallProgress(subjectNames);
    final mockData = {
      'currentCertificate': certificateData['certificate'],
      'currentDay': certificateData['currentDay'],
      'progress': overallProgress,
      'streakDays': currentStreak,
      'studyModeProgress': {
        'concept': conceptProgress,
        'practice': practiceProgress,
        'review': 0.0,
      },
      'streakInfo': {
        'currentStreak': currentStreak,
        'maxStreak': 6,
        'completedCertificates': 0,
        'completedLessons': certificateData['completedLessons'],
        'recentDays': recentDays,
      },
      'subjects': certificateData['subjects'],
      'allCertificates': [
        {
          'id': '1',
          'name': '정보처리기능사',
          'icon': 'memory',
        },
        {
          'id': '2',
          'name': '컴퓨터활용능력 2급',
          'icon': 'desktop_mac',
        },
        {
          'id': '3',
          'name': '한국사능력검정시험 심화',
          'icon': 'menu_book',
        },
      ],
    };

    final homeData = HomeData.fromJson(mockData);
    _cache = homeData;
    _cacheTimestamp = DateTime.now();
    _cachedCertificateId = _currentCertificateId;

    return homeData;
  }

  Map<String, dynamic> _getCertificateData(String certificateId) {
    switch (certificateId) {
      case '1':
        return {
          'certificate': {
            'id': '1',
            'name': '정보처리기능사',
            'icon': 'memory',
          },
          'currentDay': 8,
          'progress': 0,
          'completedLessons': 0,
          'studyModeProgress': {
            'concept': 0, 
            'practice': 0,
            'review': 0,
          },
          'subjects': [
            {
              'id': '1',
              'name': '소프트웨어개발',
              'isCompleted': false,
            },
            {
              'id': '2',
              'name': '소프트웨어설계',
              'isCompleted': false,
            },
            {
              'id': '3',
              'name': '데이터베이스',
              'isCompleted': false,
            },
            {
              'id': '4',
              'name': '네트워크',
              'isCompleted': false,
            },
          ],
        };

      case '2':
        return {
          'certificate': {
            'id': '2',
            'name': '컴퓨터활용능력 2급',
            'icon': 'desktop_mac',
          },
          'currentDay': 23,
          'progress': 0,
          'completedLessons': 0,
          'studyModeProgress': {
            'concept': 0,
            'practice': 0,
            'review': 0,
          },
          'subjects': [
            {
              'id': '1',
              'name': '컴퓨터 일반',
              'isCompleted': true,
            },
            {
              'id': '2',
              'name': '스프레드시트 일반',
              'isCompleted': false,
            },
            {
              'id': '3',
              'name': '스프레드시트 실무',
              'isCompleted': false,
            },
          ],
        };

      case '3':
        return {
          'certificate': {
            'id': '3',
            'name': '한국사능력검정시험 심화',
            'icon': 'menu_book',
          },
          'currentDay': 42,
          'progress': 0,
          'completedLessons': 0,
          'studyModeProgress': {
            'concept': 0,
            'practice': 0,
            'review': 0,
          },
          'subjects': [
            {
              'id': '1',
              'name': '선사시대와 고대',
              'isCompleted': true,
            },
            {
              'id': '2',
              'name': '고려시대',
              'isCompleted': true,
            },
            {
              'id': '3',
              'name': '조선시대',
              'isCompleted': true,
            },
            {
              'id': '4',
              'name': '근·현대사',
              'isCompleted': false,
            },
            {
              'id': '5',
              'name': '통합 정리',
              'isCompleted': false,
            },
          ],
        };

      default:
        return _getCertificateData('1');
    }
  }

  void setCurrentCertificate(String certificateId) {
    _currentCertificateId = certificateId;
  }

  void invalidateCache() {
    _cache = null;
    _cacheTimestamp = null;
    _cachedCertificateId = null;
  }
}
