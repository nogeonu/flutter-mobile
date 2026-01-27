# 🍎 iOS 앱 설치 가이드

## ⚠️ 주의사항

iOS는 Apple의 보안 정책으로 인해 App Store를 거치지 않은 앱 설치가 매우 제한적입니다.
아래 방법 중 하나를 선택하여 설치하세요.

---

## 방법 1️⃣: AltStore (권장 ✨)

### 장점
- ✅ 가장 안정적
- ✅ 자동 갱신 가능
- ✅ 무료

### 단점
- ❌ 7일마다 갱신 필요 (무료 Apple ID)
- ❌ PC/Mac + USB 케이블 필요

### 설치 과정

#### 1. 컴퓨터에 AltServer 설치

**다운로드**: https://altstore.io/

- **Mac**: AltServer.dmg
- **Windows**: AltServer.zip

#### 2. AltServer 실행
1. 다운로드한 파일 실행
2. Mac: 메뉴바에 AltServer 아이콘 표시
3. Windows: 시스템 트레이에 아이콘 표시

#### 3. iPhone에 AltStore 설치
1. iPhone을 **USB로 Mac/PC에 연결**
2. iPhone에서 **"이 컴퓨터를 신뢰하시겠습니까?"** → **신뢰**
3. Mac 메뉴바 또는 Windows 트레이에서 **AltServer 아이콘** 클릭
4. **Install AltStore** → **[내 iPhone 이름]** 선택
5. **Apple ID**와 **비밀번호** 입력
   - ⚠️ 2단계 인증 사용 시: 앱 전용 비밀번호 생성 필요
   - https://appleid.apple.com → 앱 전용 비밀번호 생성

#### 4. iPhone에서 개발자 신뢰 설정
1. iPhone: **설정** 앱 열기
2. **일반** → **VPN 및 기기 관리** (또는 **프로파일 및 기기 관리**)
3. **개발자 앱** 섹션에서 **[내 Apple ID]** 선택
4. **"[내 Apple ID] 신뢰"** 탭

#### 5. AltStore 앱 열기
iPhone 홈 화면에 **AltStore** 앱이 설치되어 있어야 함

#### 6. IPA 파일 설치
1. **konyang-hospital-app.ipa** 파일을 iPhone으로 전송
   - 방법 1: 이메일로 전송하여 iPhone에서 다운로드
   - 방법 2: iCloud Drive/Dropbox 등에 업로드
   - 방법 3: AirDrop으로 전송
2. iPhone **파일** 앱에서 IPA 파일 찾기
3. IPA 파일을 **길게 누르기** → **공유** → **AltStore로 복사**
4. 또는 **AltStore 앱** 실행 → **My Apps** → **왼쪽 상단 + 버튼** → IPA 선택

#### 7. 앱 실행
- 홈 화면에 **건양대학교병원** 앱 설치됨
- 앱 실행!

### 자동 갱신 설정 (중요!)

#### AltStore가 백그라운드에서 자동 갱신하도록 설정

1. AltStore 앱 실행 → **Settings**
2. **Background Refresh** 활성화
3. iPhone 설정 → **일반** → **백그라운드 앱 새로고침** → **AltStore** 켜기

#### 조건
- iPhone과 Mac/PC가 **같은 Wi-Fi**에 연결
- Mac/PC에서 **AltServer 실행 중**
- iPhone에서 **AltStore 백그라운드 실행**

⚠️ **7일마다 자동으로 갱신** (위 조건 충족 시)

---

## 방법 2️⃣: Sideloadly

### 장점
- ✅ 간단한 UI
- ✅ 빠른 설치

### 단점
- ❌ 7일마다 재설치 필요
- ❌ 자동 갱신 불가
- ❌ PC/Mac + USB 필요

### 설치 과정

#### 1. Sideloadly 다운로드
```
https://sideloadly.io/
```

#### 2. 설치 및 실행
1. Sideloadly 설치 후 실행
2. iPhone을 **USB로 연결**
3. iPhone에서 **"신뢰"** 선택

#### 3. IPA 설치
1. **konyang-hospital-app.ipa** 파일을 **Sideloadly 창으로 드래그**
2. **Apple ID** 입력 (iCloud 계정)
3. **Start** 버튼 클릭
4. 설치 완료까지 대기 (1-3분)

#### 4. 신뢰 설정
1. iPhone: **설정** → **일반** → **VPN 및 기기 관리**
2. **[내 Apple ID]** 선택
3. **신뢰** 탭

#### 5. 앱 실행
- 홈 화면에서 앱 실행!

⚠️ **7일 후 재설치 필요** (자동 갱신 없음)

---

## 방법 3️⃣: Xcode (개발자용)

### 장점
- ✅ 완전한 개발 환경
- ✅ 디버깅 가능

### 단점
- ❌ Mac 필수
- ❌ Xcode 설치 필요 (12GB+)
- ❌ 복잡함

### 설치 과정

#### 1. Xcode 설치
```bash
# Mac App Store에서 Xcode 설치 (무료)
# 또는 터미널에서
xcode-select --install
```

#### 2. Flutter 프로젝트 열기
```bash
cd /Users/nogeon-u/Desktop/건양대_바이오메디컬/Flutter/flutter_app
open ios/Runner.xcworkspace
```

#### 3. iPhone 연결 및 설정
1. iPhone을 **USB로 Mac에 연결**
2. Xcode 상단에서 **Runner** → **[내 iPhone]** 선택
3. **Signing & Capabilities** 탭
4. **Team** → **Add Account** → Apple ID 입력
5. **Automatically manage signing** 체크

#### 4. 실행
1. Xcode 상단 **▶️ (Run)** 버튼 클릭
2. 앱이 iPhone에 설치되고 자동 실행

---

## 방법 4️⃣: TestFlight (프로덕션 권장)

### 장점
- ✅ 가장 안정적이고 공식적인 방법
- ✅ 갱신 걱정 없음
- ✅ 베타 테스터 관리 가능

### 단점
- ❌ Apple Developer 계정 필요 ($99/년)
- ❌ App Store Connect 설정 복잡
- ❌ 초기 설정 시간 소요

### 설치 과정

#### 1. Apple Developer Program 가입
```
https://developer.apple.com/programs/
```
- 연간 $99 비용

#### 2. App Store Connect 설정
1. https://appstoreconnect.apple.com/ 접속
2. **My Apps** → **+** → **New App**
3. 앱 정보 입력

#### 3. Xcode에서 Archive
```bash
cd /Users/nogeon-u/Desktop/건양대_바이오메디컬/Flutter/flutter_app
flutter build ios --release
open ios/Runner.xcworkspace
```

1. Xcode에서 **Generic iOS Device** 선택
2. **Product** → **Archive**
3. **Distribute App** → **App Store Connect**
4. 업로드

#### 4. TestFlight 초대
1. App Store Connect → **TestFlight** 탭
2. **Testers** → **+** → 이메일 입력
3. 초대 발송

#### 5. 테스터가 앱 설치
1. iPhone에서 **TestFlight** 앱 다운로드 (App Store)
2. 초대 이메일에서 **View in TestFlight** 클릭
3. TestFlight에서 **Install** 탭

---

## 📋 방법 비교표

| 방법 | 난이도 | 비용 | 갱신 주기 | 자동 갱신 | 권장도 |
|------|--------|------|-----------|-----------|---------|
| **AltStore** | 중간 | 무료 | 7일 | ✅ 가능 | ⭐⭐⭐⭐⭐ |
| **Sideloadly** | 쉬움 | 무료 | 7일 | ❌ 불가 | ⭐⭐⭐⭐ |
| **Xcode** | 어려움 | 무료 | 7일 | ❌ 불가 | ⭐⭐⭐ |
| **TestFlight** | 복잡 | $99/년 | 없음 | ✅ | ⭐⭐⭐⭐⭐ |

---

## 🎯 권장 순서

### 개인 사용 (무료)
```
1. AltStore (권장)
2. Sideloadly (간단한 UI 선호 시)
3. Xcode (개발자)
```

### 팀/조직 배포
```
TestFlight (유료지만 가장 안정적)
```

---

## ⚠️ 7일 제한 해결 방법

### 무료 Apple ID
- 앱은 **7일마다 재서명** 필요
- AltStore 사용 시 **자동 갱신** 가능

### 유료 Apple Developer ($99/년)
- **1년** 유효
- TestFlight 사용 가능

---

## 🔧 문제 해결

### "신뢰되지 않은 개발자" 오류
```
설정 → 일반 → VPN 및 기기 관리 → [Apple ID] → 신뢰
```

### "앱을 설치할 수 없음" 오류
- Apple ID 확인
- 기기 공간 확인 (최소 100MB)
- 재시도

### AltStore가 앱을 찾지 못함
- IPA 파일을 **파일 앱**에 저장
- **공유** → **AltStore로 복사** 사용

### Sideloadly "Could not find device" 오류
- USB 케이블 재연결
- iPhone에서 "신뢰" 다시 선택
- Sideloadly 재시작

---

## 📞 추가 도움

### AltStore 공식 문서
- https://faq.altstore.io/

### Sideloadly 가이드
- https://sideloadly.io/#howto

### Apple TestFlight
- https://developer.apple.com/testflight/

---

## ✅ 설치 완료 후

앱이 설치되면:

1. **홈 화면**에서 **건양대학교병원** 앱 찾기
2. 앱 실행
3. 로그인: `shrjsdn908` / `zhdkffk4206`
4. 모든 기능 테스트

**설치 성공을 축하합니다!** 🎉

---

**마지막 업데이트**: 2025-11-14

