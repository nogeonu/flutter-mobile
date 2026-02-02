#!/bin/bash
# 다가오는 일정 연동 변경사항 커밋·푸시 스크립트
# 사용법: 터미널에서 이 스크립트 실행 (chmod +x commit_and_push.sh && ./commit_and_push.sh)

set -e
REPO_URL="https://github.com/nogeonu/flutter-mobile.git"
# 현재 Flutter 프로젝트 폴더 (스크립트 위치 기준)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
FRESH_DIR="$PARENT_DIR/Flutter_push"

echo "=== 1. 새 폴더에 저장소 클론 ==="
cd "$PARENT_DIR"
rm -rf Flutter_push 2>/dev/null || true
git clone "$REPO_URL" Flutter_push
cd Flutter_push

echo "=== 2. 수정된 3개 파일 복사 ==="
cp "$SCRIPT_DIR/chatbot_server/chatbot/urls.py" chatbot_server/chatbot/
cp "$SCRIPT_DIR/chatbot_server/chatbot/views.py" chatbot_server/chatbot/
cp "$SCRIPT_DIR/lib/services/appointment_repository.dart" lib/services/

echo "=== 3. 커밋 ==="
git add chatbot_server/chatbot/urls.py chatbot_server/chatbot/views.py lib/services/appointment_repository.dart
git commit -m "feat: 마이페이지 다가오는 일정 - 챗봇 서버 예약 API 연동

- 챗봇 서버에 GET /api/chat/appointments/ 추가 (병원 DB patients_appointment 조회)
- Flutter fetchMyAppointments에서 챗봇 API 우선 호출, 실패 시 메인 API 폴백
- 로그인 환자(patient_id) 기준 예약 목록 표시"

echo "=== 4. 푸시 ==="
git push origin main

echo "=== 완료 ==="
echo "푸시가 끝났습니다. 새로 클론한 폴더: $FRESH_DIR"
echo "이후 작업은 Flutter_push 폴더를 사용하거나, 기존 Flutter 폴더의 .git을 Flutter_push/.git으로 교체해서 복구할 수 있습니다."
