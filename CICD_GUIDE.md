# 🚀 Flutter CI/CD 파이프라인 가이드

## 📋 개요

Flutter 앱의 자동 빌드 및 배포 시스템입니다.

```
Flutter 코드 작성
    ↓
Git Push (main 브랜치)
    ↓
GitHub Actions 자동 실행
    ↓
APK 빌드 (Release)
    ↓
GitHub Releases에 자동 업로드
    ↓
Django API가 최신 버전 정보 제공
    ↓
React 웹에서 다운로드 링크 제공
```

## 🛠️ 구성 요소

### 1. GitHub Actions 워크플로우
- 파일: `.github/workflows/build-apk.yml`
- 트리거: `main` 브랜치에 `lib/`, `android/`, `pubspec.yaml` 변경 시
- 수동 실행: GitHub Actions 페이지에서 "Run workflow" 버튼

### 2. Django API
- 엔드포인트: `GET /api/patients/mobile/latest-apk/`
- 기능: GitHub Releases에서 최신 APK 정보 가져오기
- 응답 예시:
```json
{
  "version": "1.0.0",
  "build_number": "1",
  "download_url": "https://github.com/nogeonu/flutter-mobile/releases/download/v1.0.0-1/konyang-hospital-app-v1.0.0.apk",
  "release_notes": "변경사항...",
  "published_at": "2025-11-14T12:00:00Z",
  "file_size": 12345678,
  "file_name": "konyang-hospital-app-v1.0.0.apk",
  "download_count": 0
}
```

### 3. React 다운로드 페이지
- Django API를 호출하여 최신 APK 다운로드 링크 제공
- 버전 정보, 변경사항, 파일 크기 표시

## 📦 사용 방법

### Step 1: 코드 수정 및 커밋
```bash
# 코드 수정 후
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin main
```

### Step 2: 자동 빌드 확인
1. GitHub 저장소 페이지에서 "Actions" 탭 클릭
2. "Build and Release APK" 워크플로우 실행 확인
3. 빌드 진행 상황 모니터링 (약 5-10분 소요)

### Step 3: 릴리스 확인
1. 빌드 완료 후 "Releases" 탭에서 새 릴리스 확인
2. APK 파일 다운로드 링크 생성됨

### Step 4: React 웹에서 확인
```javascript
// React 컴포넌트 예시
import { useState, useEffect } from 'react';

function AppDownload() {
  const [apkInfo, setApkInfo] = useState(null);
  
  useEffect(() => {
    fetch('http://your-django-server/api/patients/mobile/latest-apk/')
      .then(res => res.json())
      .then(data => setApkInfo(data));
  }, []);
  
  if (!apkInfo) return <div>로딩 중...</div>;
  
  return (
    <div>
      <h2>건양대학교병원 환자 앱 다운로드</h2>
      <p>버전: {apkInfo.version}</p>
      <p>파일 크기: {(apkInfo.file_size / 1024 / 1024).toFixed(2)} MB</p>
      <a 
        href={apkInfo.download_url} 
        download
        className="download-button"
      >
        APK 다운로드
      </a>
      <div>
        <h3>변경사항</h3>
        <pre>{apkInfo.release_notes}</pre>
      </div>
    </div>
  );
}
```

## 🔧 설정

### GitHub 저장소 설정
1. **Settings** → **Actions** → **General**
2. **Workflow permissions**: "Read and write permissions" 선택
3. **Allow GitHub Actions to create and approve pull requests** 체크

### Django 설정
`backend/eventeye/settings.py`에 추가:
```python
FLUTTER_GITHUB_REPO = 'nogeonu/flutter-mobile'
```

## 📝 버전 관리

### 버전 번호 업데이트
`pubspec.yaml` 파일에서 버전 수정:
```yaml
version: 1.1.0+2  # 1.1.0: 버전, 2: 빌드 번호
```

### 릴리스 네이밍 규칙
- 태그: `v{version}-{build_number}` (예: `v1.0.0-1`)
- APK 파일명: `konyang-hospital-app-v{version}.apk`

## 🐛 트러블슈팅

### 빌드 실패 시
1. GitHub Actions 로그 확인
2. `flutter analyze` 에러 해결
3. `pubspec.yaml` 의존성 확인

### APK 다운로드 실패 시
1. GitHub Releases 페이지 직접 확인
2. Django API 응답 확인: `curl http://localhost:8000/api/patients/mobile/latest-apk/`
3. GitHub API rate limit 확인 (시간당 60회 제한)

## 🚨 주의사항

### 앱 서명
- 현재는 테스트용 서명 사용
- 프로덕션 배포 시 정식 keystore 필요
- keystore를 GitHub Secrets에 저장하여 CI에서 사용

### 보안
- GitHub Actions는 public 저장소에서 무료
- Private 저장소는 월 2,000분 무료 (초과 시 과금)
- APK 다운로드는 인증 없이 누구나 가능 (GitHub Releases가 공개)

## 📊 통계

### 다운로드 통계 확인
- GitHub Releases 페이지에서 다운로드 수 확인
- Django API 응답의 `download_count` 필드

### CI/CD 메트릭
- GitHub Actions 페이지에서 빌드 시간, 성공률 확인

## 🔄 향후 개선 계획

1. **자동 버전 관리**: semantic-release로 자동 버전 증가
2. **코드 서명**: 프로덕션 keystore 적용
3. **테스트 자동화**: Unit test, Integration test 실행
4. **멀티 플랫폼**: iOS 빌드 추가 (macOS runner 필요)
5. **통계 대시보드**: 다운로드 통계, 사용자 피드백 수집

## 📚 참고 자료

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Build & Release](https://docs.flutter.dev/deployment/android)
- [GitHub Releases API](https://docs.github.com/en/rest/releases)

