# Push Notifications — FCM / APNs Setup

## Current state
Local notifications are wired via `flutter_local_notifications`.
Daily 9 PM reminder schedules when the user enables notifications in Settings.

## To enable Firebase Cloud Messaging (FCM)

### 1. Firebase project
1. Go to https://console.firebase.google.com
2. Create project (or reuse existing).
3. Add iOS app: Bundle ID `com.kkeutgong.app` → download `GoogleService-Info.plist` → place in `ios/Runner/`.
4. Add Android app: Package `com.kkeutgong.app` → download `google-services.json` → place in `android/app/`.

### 2. Flutter dependencies
Add to `pubspec.yaml`:
```yaml
firebase_core: ^3.x.x
firebase_messaging: ^15.x.x
```

### 3. iOS APNs key
1. Apple Developer → Certificates, IDs & Profiles → Keys → Create key with Apple Push Notifications service (APNs).
2. Download the `.p8` file.
3. In Firebase Console → Project Settings → Cloud Messaging → Apple app configuration → upload the `.p8` key.

### 4. Android FCM
No extra steps needed if `google-services.json` is in place.
Add to `android/app/build.gradle.kts`:
```kotlin
id("com.google.gms.google-services")
```
And in `android/build.gradle.kts`:
```kotlin
id("com.google.gms.google-services") version "4.4.x" apply false
```

### 5. Integrate in NotificationService
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initFCM() async {
  await Firebase.initializeApp();
  final fcm = FirebaseMessaging.instance;
  final token = await fcm.getToken();
  // Send token to backend: POST /api/users/me/push-token
  FirebaseMessaging.onMessage.listen(_handleForeground);
  FirebaseMessaging.onBackgroundMessage(_handleBackground);
}
```

### 6. Backend
Backend should store FCM token per user and send push via Firebase Admin SDK.
