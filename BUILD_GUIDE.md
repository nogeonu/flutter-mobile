# 🏗️ 빌드 가이드

## 📱 지원 플랫폼

- 🤖 **Android**: APK 자동 빌드 (무료)
- 🍎 **iOS**: IPA 자동 빌드 (GitHub macOS runner - 유료)

---

## 🚀 자동 빌드 (CI/CD)

### 1️⃣ 통합 빌드 (APK + iOS)

**워크플로우**: `.github/workflows/build-all.yml`

#### 트리거 조건
- `main` 브랜치에 push
- `v*` 태그 생성
- 수동 실행 (`Actions` 탭에서)

#### 빌드 과정
```
1. Android 빌드 (Ubuntu runner)
   ↓
2. iOS 빌드 (macOS runner) - 병렬 실행
   ↓
3. Release 생성 및 APK/IPA 업로드
```

#### 결과물
- `app-release.apk` (Android)
- `konyang-hospital-app.ipa` (iOS)

---

### 2️⃣ Android 전용 빌드

**워크플로우**: `.github/workflows/build-apk.yml`

#### 트리거 조건
- 수동 실행만 가능 (Actions 탭)

#### 사용 시기
- iOS 빌드 불필요 시
- macOS runner 비용 절감

---

### 3️⃣ iOS 전용 빌드

**워크플로우**: `.github/workflows/build-ios.yml`

#### 트리거 조건
- `main` 브랜치 push (`ios/**` 변경 시)
- 수동 실행

#### 주의사항
⚠️ **macOS runner는 유료입니다**
- GitHub Free: 월 제한 있음
- GitHub Pro/Team/Enterprise: 더 많은 무료 시간

---

## 📦 수동 빌드

### Android APK

```bash
# 1. 의존성 설치
flutter pub get

# 2. 릴리스 빌드
flutter build apk --release

# 3. 결과물
# build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA

```bash
# 1. 의존성 설치
flutter pub get

# 2. CocoaPods 설치
cd ios
pod install
cd ..

# 3. iOS 빌드 (코드서명 없이)
flutter build ios --release --no-codesign

# 4. IPA 생성
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r app.ipa Payload
rm -rf Payload
```

---

## 🔄 버전 관리

### pubspec.yaml
```yaml
version: 1.0.5+12
#        ^^^^^ ^^
#        |     |
#        |     +-- 빌드 번호 (Build Number)
#        +-------- 버전 (Version Name)
```

### 버전 업데이트
```bash
# version을 수정하고 push하면 자동 빌드
vim pubspec.yaml
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.6+13"
git push origin main
```

---

## 📥 다운로드 & 설치

### 1. GitHub Releases

https://github.com/nogeonu/flutter-mobile/releases

최신 릴리스에서 APK 또는 IPA 다운로드

### 2. Android 설치

1. `app-release.apk` 다운로드
2. 설정 → 보안 → 알 수 없는 출처 허용
3. APK 파일 실행

### 3. iOS 설치 (어려움 ⚠️)

iOS는 Apple의 제한으로 인해 설치가 복잡합니다:

#### 방법 1: TestFlight (권장)
- App Store Connect에 업로드 필요
- 베타 테스터 초대

#### 방법 2: Xcode (개발자)
```bash
# Mac에서 Xcode 필요
open -a Xcode ios/Runner.xcworkspace
# Xcode에서 실기기 연결 후 Run
```

#### 방법 3: 사이드로딩 도구
- **AltStore**: https://altstore.io/
- **Sideloadly**: https://sideloadly.io/
- 무료, 7일마다 재설치 필요

---

## 🛠️ CI/CD 설정

### GitHub Actions Secrets

필요한 Secret 없음 (현재 설정)

### 향후 추가 가능
- `ANDROID_KEYSTORE`: APK 서명용
- `IOS_CERTIFICATE`: iOS 코드서명용

---

## 💰 비용

### GitHub Actions 무료 사용량

| 플랜 | Linux/Windows | macOS |
|------|---------------|-------|
| Free | 2,000분/월 | 0분 (비활성화 권장) |
| Pro | 3,000분/월 | 50분/월 |
| Team | 3,000분/월 | 50분/월 |

### 비용 절감 팁

1. **iOS 빌드 최소화**
   - Android만 자주 빌드
   - iOS는 필요할 때만 수동 실행

2. **Self-hosted Runner**
   - 자체 Mac 서버 사용
   - 무제한 무료 빌드

3. **빌드 조건 제한**
   ```yaml
   on:
     push:
       paths:
         - 'lib/**'  # 코드 변경 시만
   ```

---

## 🔍 트러블슈팅

### Android 빌드 실패

```bash
# 로컬에서 확인
flutter clean
flutter pub get
flutter build apk --release
```

### iOS 빌드 실패

```bash
# CocoaPods 재설치
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter build ios --release --no-codesign
```

### GitHub Actions 실패

1. Actions 탭에서 로그 확인
2. 로컬에서 동일 명령 실행
3. 실패 시 Issue 생성

---

## 📚 참고 자료

- [Flutter 공식 문서 - 빌드](https://docs.flutter.dev/deployment)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Flutter iOS 배포](https://docs.flutter.dev/deployment/ios)
- [Flutter Android 배포](https://docs.flutter.dev/deployment/android)

---

## ✅ 체크리스트

### 릴리스 전 확인사항

- [ ] 버전 번호 증가 (`pubspec.yaml`)
- [ ] API URL 확인 (`lib/config/api_config.dart`)
- [ ] 로컬 빌드 테스트
- [ ] 로컬 앱 실행 테스트
- [ ] Git push 전 코드 리뷰
- [ ] CI/CD 빌드 성공 확인
- [ ] Release 노트 작성

---

**Last Updated**: 2025-11-14

