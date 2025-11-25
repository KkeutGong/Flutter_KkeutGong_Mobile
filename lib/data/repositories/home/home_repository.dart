import 'package:kkeutgong_mobile/domain/models/home/home_data.dart';

class HomeRepository {
  // 현재 선택된 자격증 ID (실제로는 서버나 로컬 저장소에서 가져올 값)
  String _currentCertificateId = '1';

  Future<HomeData> getHomeData() async {
    await Future.delayed(const Duration(milliseconds: 500));

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

    // 자격증별 데이터 정의
    final certificateData = _getCertificateData(_currentCertificateId);

    final mockData = {
      'currentCertificate': certificateData['certificate'],
      'currentDay': certificateData['currentDay'],
      'progress': certificateData['progress'],
      'streakDays': currentStreak,
      'studyModeProgress': certificateData['studyModeProgress'],
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

    return HomeData.fromJson(mockData);
  }

  Map<String, dynamic> _getCertificateData(String certificateId) {
    switch (certificateId) {
      case '1': // 정보처리기능사 - 초반 진행 중
        return {
          'certificate': {
            'id': '1',
            'name': '정보처리기능사',
            'icon': 'memory',
          },
          'currentDay': 8,
          'progress': 0.206, // 20.6% 진행
          'completedLessons': 0,
          'studyModeProgress': {
            'concept': 0.62,  // 개념학습 62% 완료
            'practice': 0.0,  // 문제풀이 시작 전
            'review': 0.0,    // 오답노트 시작 전
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

      case '2': // 컴퓨터활용능력 2급 - 중반 진행 중
        return {
          'certificate': {
            'id': '2',
            'name': '컴퓨터활용능력 2급',
            'icon': 'desktop_mac',
          },
          'currentDay': 23,
          'progress': 0.58, // 58% 진행
          'completedLessons': 18,
          'studyModeProgress': {
            'concept': 1.0,   // 개념학습 완료
            'practice': 0.45, // 문제풀이 45% 완료
            'review': 0.12,   // 오답노트 12% 완료
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

      case '3': // 한국사능력검정시험 심화 - 거의 완료
        return {
          'certificate': {
            'id': '3',
            'name': '한국사능력검정시험 심화',
            'icon': 'menu_book',
          },
          'currentDay': 42,
          'progress': 0.89, // 89% 진행
          'completedLessons': 35,
          'studyModeProgress': {
            'concept': 1.0,   // 개념학습 완료
            'practice': 1.0,  // 문제풀이 완료
            'review': 0.67,   // 오답노트 67% 완료
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
}
