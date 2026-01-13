# 🏥 CDSSentials - 건양대학교병원 환자 모바일 서비스

> Flutter로 개발된 병원 내원 지원용 모바일 애플리케이션으로, 환자의 병원 방문 전·중·후 전체 여정을 스마트폰 하나로 관리할 수 있도록 돕는 원스톱 병원 서비스 앱입니다.

[![Flutter](https://img.shields.io/badge/Flutter-3.27-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![Django](https://img.shields.io/badge/Django-REST-green.svg)](https://www.djangoproject.com)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

---

## 📱 주요 기능

### 🔐 인증 및 개인화
- **JWT 기반 로그인**: 안전한 세션 관리 및 환자 정보 연동
- **AppState 전역 상태 관리**: 로그인한 사용자 정보를 모든 화면에서 일관되게 사용
- **개인화된 대시보드**: 환자별 맞춤 진료 일정 및 건강 알림

### 📅 진료 예약
- **실시간 예약 시스템**: 의사 선택, 날짜/시간 선택을 통한 간편한 예약
- **예약 관리**: 내 예약 목록 조회 및 일정 확인
- **로그인 가드**: 예약 기능 접근 시 자동 인증 확인

### 🗺️ 지도 및 네비게이션
- **약국 찾기**: 현재 위치 기반 최근 약국 검색 및 경로 안내
- **병원 길찾기**: 건양대학교병원까지 자동 경로 안내
- **Kakao Map 연동**: KakaoMap 앱 또는 웹을 통한 실시간 네비게이션

### 📢 고객센터
- **고객의 소리**: 온라인 접수 폼 및 파일 첨부 기능
- **주요 전화번호**: 병원 주요 부서 연락처 빠른 연결
- **FAQ 및 문의**: 자주 묻는 질문 및 고객 지원

### 🔔 건강 알림
- **로그인 상태별 알림**: 개인화된 건강 정보 제공
- **다가오는 일정**: 예약된 진료 일정 자동 표시

---

## 🛠️ 기술 스택

### 모바일
- **Flutter 3.27** - 크로스 플랫폼 모바일 앱 개발
- **Dart 3.0+** - 프로그래밍 언어
- **ChangeNotifier** - 상태 관리 (AppState)
- **Repository 패턴** - 데이터 레이어 추상화

### 백엔드
- **Django REST Framework** - RESTful API 서버
- **MySQL 8** - 관계형 데이터베이스
- **JWT** - 인증 토큰 관리
- **Django ORM** - 데이터베이스 추상화

### 지도 및 위치
- **Kakao Map Platform** - 지도 및 장소 검색 API
- **kakao_map_plugin** - Flutter 지도 플러그인
- **geolocator** - GPS 위치 서비스
- **url_launcher** - 외부 앱/웹 링크 실행

### CI/CD & 배포
- **GitHub Actions** - 자동 빌드 및 배포
- **GitHub Releases** - APK/IPA 배포 관리
- **AltStore** - iOS 사이드로딩
- **React Web** - 다운로드 페이지

---

## 🏗️ 시스템 아키텍처

```
┌──────────────┐       ┌──────────────────────┐
│ Flutter App  │<─────>│ Django REST Backend  │<───> MySQL
│ (iOS/Android)│       │  (patients app)      │
└────┬─────────┘       └────┬─────────────────┘
     │                        │
     │                        ├─ React Web (병원 홈페이지 & 다운로드)
     │                        └─ Flask Model Server (AI/분석, 추후 연동)
     │
     └─ GitHub Actions CI/CD ──> GitHub Releases (APK/IPA 배포)
```

### 데이터 흐름

1. **로그인 흐름**: Flutter App → Login API → JWT+환자ID → AppState 저장
2. **예약 흐름**: Flutter App → 예약 API → MySQL 저장 → 예약 목록 반환
3. **지도 흐름**: Flutter App → geolocator → Kakao 검색 API → KakaoMap 경로

---

## 📦 프로젝트 구조

```
lib/
├── config/              # 설정 파일
│   ├── api_config.dart  # API 엔드포인트 설정
│   └── map_config.dart  # 지도 설정
├── data/                # 데이터 모델
│   └── feature_item.dart
├── models/              # 도메인 모델
│   ├── appointment.dart
│   ├── doctor.dart
│   ├── medical_record.dart
│   ├── patient_profile.dart
│   └── patient_session.dart
├── screens/             # 화면 위젯
│   ├── login_screen.dart
│   ├── reservation_screen.dart
│   ├── pharmacy_screen.dart
│   ├── hospital_navigation_screen.dart
│   └── ...
├── services/             # 비즈니스 로직 및 API 호출
│   ├── api_client.dart
│   ├── patient_repository.dart
│   ├── appointment_repository.dart
│   └── kakao_local_service.dart
├── state/               # 전역 상태 관리
│   └── app_state.dart
├── theme/               # 테마 설정
│   └── app_theme.dart
└── widgets/             # 재사용 가능한 위젯
    ├── feature_card.dart
    └── greeting_card.dart
```

---

## 🚀 시작하기

### 필수 요구사항

- Flutter SDK 3.27 이상
- Dart SDK 3.0 이상
- Android Studio / Xcode (각 플랫폼별)
- Kakao Map API 키

### 설치 방법

1. **저장소 클론**
```bash
git clone <repository-url>
cd flutter_app
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **환경 설정**
   - `lib/config/api_config.dart`에서 API 엔드포인트 설정
   - `lib/config/map_config.dart`에서 Kakao Map API 키 설정

4. **실행**
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### 빌드

```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ipa --release
```

---

## 🔄 CI/CD 파이프라인

### GitHub Actions 워크플로우

1. **트리거**: `main` 브랜치 push 또는 수동 실행
2. **분석**: `flutter analyze`로 코드 품질 확인
3. **빌드**: Android APK 및 iOS IPA 자동 빌드
4. **배포**: GitHub Releases에 자동 업로드

### 배포 흐름

```
개발 ─git push─> GitHub Actions ─build─> GitHub Releases
                                  └─ React 웹에서 다운로드 버튼 제공
                                  └─ Django API latest-apk 응답으로 앱 최신 버전 표시
```

자세한 내용은 [CICD_GUIDE.md](./CICD_GUIDE.md)를 참조하세요.

---

## 📚 주요 구현 요소

### AppState (전역 상태 관리)
- 로그인 세션 및 환자 정보 저장
- `ChangeNotifier`를 통한 상태 변경 알림
- 모든 화면에서 일관된 사용자 정보 제공

### Repository 패턴
- API 호출 로직을 UI에서 분리
- 에러 처리 및 데이터 변환 중앙화
- 테스트 용이성 향상

### Django REST ViewSet
- 모델별 CRUD 작업 자동화
- 인증 및 권한 관리
- 직렬화를 통한 JSON 응답 생성

---

## 🗺️ Kakao Map 연동

### 약국 찾기
1. `geolocator`로 현재 위치 획득
2. Kakao 장소 검색 API로 최근 약국 검색
3. 지도에 마커 표시 및 경로 안내 URL 생성

### 병원 길찾기
1. 사용자 위치 자동 감지
2. 건양대학교병원 고정 좌표로 경로 생성
3. KakaoMap 앱 또는 웹으로 자동 연결

---

## 📱 iOS 설치 (AltStore)

1. **준비**: iPhone Developer Mode 활성화, AltServer 설치
2. **설치**: AltStore 앱에서 GitHub Releases의 IPA 파일 설치
3. **업데이트**: 새 IPA 파일로 덮어쓰기
4. **재서명**: 7일마다 AltStore에서 Refresh All 실행

자세한 내용은 [IOS_INSTALL_GUIDE.md](./IOS_INSTALL_GUIDE.md)를 참조하세요.

---

## 🐛 문제 해결

| 이슈 | 원인 | 해결 |
|------|------|------|
| 예약 API 400 | 필드명 불일치 (`patient_identifier` vs `patient_id`) | Flutter/Django 필드명 통일 |
| Kakao 경로 목적지 미표시 | URL 파라미터 누락 | `sp/sn/ep/en/by` 모두 포함 |
| 마커 이미지 깨짐 | 외부 이미지 로딩 실패 | 기본 마커 + 이모지 사용 |
| CI analyze 실패 | 경고로 인한 실패 | `--no-fatal-infos/warnings` 옵션 추가 |

---

## 📈 버전 관리

- 버전 형식: `X.Y.Z+build` (예: `1.0.10+18`)
- GitHub Release에 자동 업로드
- 각 릴리스에 변경사항 및 빌드 정보 포함

---

## 🔮 향후 계획

- [ ] Firebase Push 알림 연동
- [ ] 챗봇(Flask 모델) 연계
- [ ] 자동 업데이트 알림 기능
- [ ] 관리자 대시보드 통합
- [ ] 서비스 고도화 및 성능 최적화

---

## 👥 팀

건양대학교병원 환자 모바일 서비스 개발팀

---

## 📄 라이선스

이 프로젝트는 건양대학교병원 내부 사용을 위한 프로젝트입니다.

---

## 📞 문의

프로젝트 관련 문의사항이 있으시면 이슈를 등록해주세요.

---

**Made with ❤️ using Flutter**
