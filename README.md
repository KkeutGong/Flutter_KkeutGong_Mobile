# 끝공 (KkeutGong) Mobile

AI 기반 자격증 학습 앱. iOS / Android.

## 빠른 시작

```bash
flutter pub get
cp assets/config/.env.example assets/config/.env  # 없으면 .env 직접 편집
flutter run -d <device-id>
```

백엔드(`../kkeutgong-backend`)가 `:3000`에서 실행 중이어야 합니다.

## 환경 변수 (`assets/config/.env`)

| Key | 용도 | 발급처 |
| --- | --- | --- |
| `API_BASE_URL` | 백엔드 주소 | dev: `http://localhost:3000/api` |
| `KAKAO_NATIVE_APP_KEY` | 카카오 로그인 | https://developers.kakao.com → 내 애플리케이션 → 앱 키 |
| `GOOGLE_CLIENT_ID` | 구글 로그인 (iOS+Android 별도) | https://console.cloud.google.com → 사용자 인증 정보 |
| `SENTRY_DSN` | 크래시 리포팅 (선택) | https://sentry.io → 프로젝트 설정 → Client Keys |
| `APP_STORE_URL` | 강제 업데이트 시 이동할 URL | Apple App Store URL |
| `PLAY_STORE_URL` | 강제 업데이트 시 이동할 URL | Google Play URL |

## OAuth 설정

### 카카오
1. https://developers.kakao.com 에서 앱 생성
2. **플랫폼**: iOS Bundle ID `com.kkeutgong.app`, Android 패키지명 `com.kkeutgong.app` + 키 해시 등록
3. **카카오 로그인** 활성화, **Redirect URI** 등록
4. **앱 키 → 네이티브 앱 키** 복사 → `.env`의 `KAKAO_NATIVE_APP_KEY`
5. iOS `Info.plist`에 `LSApplicationQueriesSchemes` (`kakaokompassauth`, `kakaolink`) + URL scheme `kakao{NATIVE_APP_KEY}` 추가
6. Android `AndroidManifest.xml`에 intent-filter (`kakao{NATIVE_APP_KEY}`) 추가

### 구글
1. https://console.cloud.google.com → APIs & Services → Credentials
2. **OAuth 클라이언트 ID** 2개 생성 (iOS, Android)
3. iOS: GoogleService-Info.plist 다운로드 → `ios/Runner/`에 추가, `REVERSED_CLIENT_ID` URL scheme을 `Info.plist`에 등록
4. Android: SHA-1 fingerprint 등록 (`cd android && ./gradlew signingReport`)

### 애플 (iOS만)
1. Xcode → Runner 프로젝트 → Signing & Capabilities → **+ Capability** → Sign In with Apple
2. `Runner.entitlements`에 `com.apple.developer.applesignin` 자동 추가됨
3. https://developer.apple.com → Certificates, Identifiers & Profiles → 앱 ID에 Sign In with Apple 활성화

## 빌드

```bash
flutter build ios --release        # iOS (TestFlight/AppStore)
flutter build apk --release        # Android (사이드로드/시험)
flutter build appbundle --release  # Android (Play Store)
```

## 자주 쓰는 작업

```bash
# Bundle ID 변경 (이미 com.kkeutgong.app으로 적용됨)
dart run rename setBundleId --value com.kkeutgong.app

# 런처 아이콘 재생성 (assets/icons/app_icon.png 변경 후)
dart run flutter_launcher_icons

# 다국어 코드 재생성 (lib/l10n/*.arb 변경 후)
flutter gen-l10n

# 분석 (커밋 전 권장)
flutter analyze
```

## 아키텍처

```
lib/
├── core/                       # 인프라
│   ├── api/api_client.dart    # HTTP + JWT 자동 헤더 + 401 refresh
│   ├── auth/token_store.dart  # flutter_secure_storage 래퍼
│   ├── notifications/         # flutter_local_notifications
│   ├── routes/                # AppRoutes (welcome/onboarding/main 등)
│   ├── session/               # 메모리 캐시 (userId, currentCertificateId)
│   └── version/version_gate.dart  # /api/health → forceUpdate / maintenance 게이트
├── data/repositories/          # 백엔드 호출 계층
│   ├── auth/                  # 카카오/구글/애플 OAuth + JWT 발급
│   ├── home/                  # GET /home
│   └── study/                 # 개념/문제풀이/모의고사
├── domain/models/              # 데이터 모델 (fromJson)
├── presentation/
│   ├── viewmodels/            # ChangeNotifier 기반 상태
│   ├── views/                 # 페이지 위젯
│   │   ├── auth/              # 로그인
│   │   ├── onboarding/        # 자격증 선택 → 시험일 → 학습 시간
│   │   ├── home/              # 홈
│   │   ├── study/             # 개념/문제풀이/모의고사
│   │   ├── profile/           # 설정 (탈퇴/로그아웃/약관/라이선스)
│   │   └── system/            # 강제업데이트/점검 화면
│   └── widgets/common/        # CustomButton, ErrorState, EmptyState
└── l10n/                      # 한/영 번역 파일 (.arb)
```

## 부팅 시퀀스 (`main.dart`)

1. dotenv 로드
2. Kakao SDK 초기화 (key 있을 때만)
3. NotificationService init
4. Sentry init (DSN 있을 때만)
5. `runApp` → `MainApp._boot()`:
   - 테마 prefs 로드
   - `GET /api/health` → forceUpdate / maintenance 처리
   - TokenStore에서 access token 확인
   - 있으면 `/users/me` 호출로 검증 (실패 시 자동 refresh)
   - onboarding 완료 여부에 따라 main 또는 onboarding으로 라우팅

## QA 자동화

`agent-device-flutter` + Claude Code의 `qa-app` 스킬을 활용 (`~/.claude/skills/qa-app/SKILL.md`).
주요 인터랙션 위젯에 Semantics 라벨 부착 완료 (`concept-known-toggle`, `mock-exam-submit` 등).

## 출시 전 점검

`../legal-and-store/release-checklist.md` 참고.

## 라이선스

Private — © 끝공 [회사명]
