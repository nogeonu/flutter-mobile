#!/bin/bash

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  챗봇 서버 자동 배포 스크립트${NC}"
echo -e "${GREEN}========================================${NC}"

# GCP 인스턴스 정보
INSTANCE_NAME="koyang-2510"
ZONE="us-central1-b"
REMOTE_USER="shrjsdn908"
REMOTE_PATH="/srv/django-react/app/backend"
SERVICE_NAME="chatbot-service.service"

# 1. 로컬 코드 준비
echo -e "\n${YELLOW}[1/6] 로컬 chatbot 코드 확인 중...${NC}"
if [ ! -d "./chatbot_server/chatbot" ]; then
    echo -e "${RED}오류: chatbot_server/chatbot 폴더를 찾을 수 없습니다.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 로컬 코드 확인 완료${NC}"

# 2. 서버로 코드 업로드
echo -e "\n${YELLOW}[2/6] 서버로 코드 업로드 중...${NC}"
gcloud compute scp --recurse \
    ./chatbot_server/chatbot \
    ${INSTANCE_NAME}:/tmp/chatbot_deploy \
    --zone=${ZONE}

if [ $? -ne 0 ]; then
    echo -e "${RED}오류: 코드 업로드 실패${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 코드 업로드 완료${NC}"

# 3. 서버에서 배포 명령 실행
echo -e "\n${YELLOW}[3/6] 서버에 배포 중...${NC}"
gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} << 'EOF'
set -e

echo "🔹 기존 chatbot 백업 중..."
cd /srv/django-react/app/backend
if [ -d "chatbot" ]; then
    sudo mv chatbot chatbot_backup_$(date +%Y%m%d_%H%M%S)
fi

echo "🔹 새 코드 배포 중..."
sudo mv /tmp/chatbot_deploy /srv/django-react/app/backend/chatbot
sudo chown -R shrjsdn908:shrjsdn908 /srv/django-react/app/backend/chatbot

echo "✓ 코드 배포 완료"
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}오류: 서버 배포 실패${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 서버 배포 완료${NC}"

# 4. 필요한 Python 패키지 설치
echo -e "\n${YELLOW}[4/6] Python 패키지 설치 중...${NC}"
gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} << 'EOF'
set -e

cd /srv/django-react/app/backend

echo "🔹 Python 패키지 설치 중..."
sudo .venv/bin/pip install -q \
    pydantic-settings \
    sentence-transformers \
    faiss-cpu \
    torch \
    torchvision \
    pillow

echo "✓ 패키지 설치 완료"
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}오류: 패키지 설치 실패${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 패키지 설치 완료${NC}"

# 5. Django 마이그레이션
echo -e "\n${YELLOW}[5/6] Django 마이그레이션 실행 중...${NC}"
gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} << 'EOF'
set -e

cd /srv/django-react/app/backend

echo "🔹 마이그레이션 실행 중..."
.venv/bin/python manage.py migrate chatbot --noinput

echo "✓ 마이그레이션 완료"
EOF

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}경고: 마이그레이션 실패 (계속 진행)${NC}"
fi
echo -e "${GREEN}✓ 마이그레이션 완료${NC}"

# 6. 서비스 재시작
echo -e "\n${YELLOW}[6/6] 챗봇 서비스 재시작 중...${NC}"
gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE} << 'EOF'
set -e

echo "🔹 기존 프로세스 정리 중..."
# 8001 포트 사용 중인 프로세스 종료
sudo lsof -ti:8001 | xargs -r sudo kill -9 || true

echo "🔹 서비스 재시작 중..."
sudo systemctl restart chatbot-service.service

# 5초 대기
sleep 5

echo "🔹 서비스 상태 확인 중..."
sudo systemctl status chatbot-service.service --no-pager | head -20

EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}오류: 서비스 재시작 실패${NC}"
    exit 1
fi

# 7. 배포 완료 및 테스트
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  배포 완료!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n서버 정보:"
echo -e "  • 챗봇 API: ${GREEN}http://34.42.223.43:8001/api/chat/${NC}"
echo -e "  • 예약 가능 시간: ${GREEN}http://34.42.223.43:8001/api/chat/available-time-slots/${NC}"
echo -e "  • 피부 분석: ${GREEN}http://34.42.223.43:8001/api/chat/skin/analyze/${NC}"

echo -e "\n${YELLOW}테스트 명령:${NC}"
echo -e "  curl -X POST http://34.42.223.43:8001/api/chat/ \\"
echo -e "    -H 'Content-Type: application/json' \\"
echo -e "    -d '{\"message\": \"안녕하세요\", \"session_id\": \"test\"}'"

echo -e "\n${YELLOW}서버 로그 확인:${NC}"
echo -e "  gcloud compute ssh ${INSTANCE_NAME} --zone=${ZONE}"
echo -e "  journalctl -u ${SERVICE_NAME} -f"

echo -e "\n${GREEN}배포가 완료되었습니다!${NC}"
