import json
import logging
import uuid
from django.http import JsonResponse
from django.utils import timezone
from django.db import connections
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST, require_GET

from chatbot.models import ChatMessage
from chatbot.services.rag import run_rag_with_cache
from chatbot.services.tooling import execute_tool, build_tool_context

logger = logging.getLogger(__name__)

AUTH_REQUIRED_REPLY = "로그인 후 이용해 주세요, 전화 문의는 대표번호 1577-3330으로 부탁드립니다."
RESERVATION_LOGIN_GUARD_CUES = [
    "예약",
    "예약내역",
    "예약 내역",
    "예약이력",
    "예약 이력",
    "예약 기록",
    "예약조회",
    "예약 조회",
    "예약확인",
    "예약 확인",
    "예약시간",
    "예약 시간",
    "예약일정",
    "예약 일정",
    "예약스케줄",
    "예약 스케줄",
    "예약취소",
    "예약 취소",
    "예약변경",
    "예약 변경",
]


@csrf_exempt
@require_POST
# API endpoint: handles chat POST requests and returns chatbot response JSON.
def chat_view(request):
    try:
        payload = json.loads(request.body.decode("utf-8"))
    except json.JSONDecodeError:
        return JsonResponse({"error": "잘못된 JSON 형식입니다."}, status=400)

    message = payload.get("message")
    if not message:
        return JsonResponse({"error": "message 필드가 필요합니다."}, status=400)

    session_id = payload.get("session_id", "")
    metadata = payload.get("metadata") or {}
    if not isinstance(metadata, dict):
        metadata = {}
    auth_keys = {
        "patient_id",
        "patient_identifier",
        "patient_phone",
        "account_id",
        "patient_pk",
        "auth_user_id",
        "user_id",
    }
    # 클라이언트에서 보낸 인증 정보를 신뢰 (Flutter 앱에서 직접 보낸 정보)
    # 보안을 위해 나중에 토큰 기반 인증으로 변경 고려
    has_auth = any(metadata.get(key) for key in auth_keys)
    
    # 인증 정보 로깅 (디버깅용)
    if has_auth:
        auth_info = {k: metadata.get(k) for k in auth_keys if metadata.get(k)}
        logger.info(
            "chat auth: request_id=%s session_id=%s has_auth=True auth_keys=%s",
            payload.get("request_id", ""),
            session_id,
            list(auth_info.keys()),
        )
    else:
        logger.info(
            "chat auth: request_id=%s session_id=%s has_auth=False metadata_keys=%s",
            payload.get("request_id", ""),
            session_id,
            list(metadata.keys()),
        )
    
    # normalized_message를 먼저 정의
    normalized_message = message.strip()
    
    if session_id:
        # 최근 10개 메시지에서 컨텍스트 복원 (Slot-Filling Recovery)
        recent_messages = ChatMessage.objects.filter(session_id=session_id).order_by("-created_at")[:10]
        
        # 예약 관련 키워드가 있을 때만 예약 컨텍스트 복원
        is_reservation_query = any(keyword in normalized_message for keyword in [
            "예약", "진료", "의사", "선생님", "변경", "취소", "날짜", "시간"
        ])
        
        # 인증 정보는 항상 복원 (보안 체크는 유지)
        auth_context_keys = [
            "patient_id", "patient_identifier", "patient_phone",
            "account_id", "patient_pk", "auth_user_id", "user_id"
        ]
        
        # 예약 관련 컨텍스트는 예약 질문일 때만 복원
        reservation_context_keys = [
            "doctor_name", "doctor_id", "doctor", "doctorId", "doctor_code",
            "department", "dept"
        ]
        
        # 마지막 봇 메시지 찾기 (버튼 클릭 컨텍스트 감지용)
        last_bot_message = None
        for msg in recent_messages:
            # ChatMessage 모델에는 is_user 필드가 없음 - bot_answer를 사용
            if msg.bot_answer:
                last_bot_message = msg.bot_answer
                break
        
        if last_bot_message:
            metadata["last_bot_answer"] = last_bot_message
            logger.info(f"[views] last_bot_answer set: {last_bot_message[:100]}")
        
        for msg in recent_messages:
            if not isinstance(msg.metadata, dict):
                continue
            
            # 인증 정보 복원
            for key in auth_context_keys:
                if key not in metadata and msg.metadata.get(key):
                    if key in auth_keys and not has_auth:
                        continue
                    metadata[key] = msg.metadata.get(key)
            
            # 예약 관련 정보는 예약 질문일 때만 복원
            if is_reservation_query:
                for key in reservation_context_keys:
                    if key not in metadata and msg.metadata.get(key):
                        metadata[key] = msg.metadata.get(key)
    
    # 세션 히스토리에서 인증 정보를 복원한 후 다시 체크
    has_auth = any(metadata.get(key) for key in auth_keys)
    
    request_id = payload.get("request_id") or metadata.get("request_id") or uuid.uuid4().hex
    metadata["request_id"] = request_id

    guard_match = (
        not has_auth
        and normalized_message
        and any(cue in normalized_message for cue in RESERVATION_LOGIN_GUARD_CUES)
    )
    result = None
    if guard_match:
        logger.info(
            "chat auth gate: request_id=%s session_id=%s",
            request_id,
            session_id,
        )
        result = {"reply": AUTH_REQUIRED_REPLY, "sources": []}

    if result is None:
        try:
            logger.info(
                "chat request: request_id=%s session_id=%s message_len=%s",
                request_id,
                session_id,
                len(message),
            )
            result = run_rag_with_cache(message, session_id=session_id, metadata=metadata)
        except FileNotFoundError as exc:
            return JsonResponse(
                {
                    "error": "지식 베이스가 준비되지 않았습니다. 먼저 문서를 색인화해주세요.",
                    "detail": str(exc),
                },
                status=503,
            )
        except ValueError as exc:
            return JsonResponse({"error": str(exc)}, status=400)
        except Exception as exc:  # pragma: no cover
            return JsonResponse({"error": f"RAG 파이프라인 오류: {exc}"}, status=500)

    hidden_sources = []
    ChatMessage.objects.create(
        session_id=session_id,
        user_question=message,
        bot_answer=result.get("reply", ""),
        sources=hidden_sources,
        metadata=metadata,
    )

    result_with_id = dict(result)
    result_with_id["request_id"] = request_id
    result_with_id["sources"] = hidden_sources
    return JsonResponse(result_with_id, status=200)


@csrf_exempt
@require_POST
def available_time_slots_view(request):
    """예약 가능 시간 조회 전용 엔드포인트"""
    try:
        payload = json.loads(request.body.decode("utf-8"))
    except json.JSONDecodeError as e:
        logger.error("available_time_slots_view: JSON decode error: %s", e)
        return JsonResponse({"error": "잘못된 JSON 형식입니다."}, status=400)

    date_str = payload.get("date")
    if not date_str:
        logger.error("available_time_slots_view: date 필드 없음")
        return JsonResponse({"error": "date 필드가 필요합니다."}, status=400)

    session_id = payload.get("session_id", "")
    metadata = payload.get("metadata") or {}
    if not isinstance(metadata, dict):
        metadata = {}

    doctor_id = payload.get("doctor_id")
    doctor_code = payload.get("doctor_code")
    
    logger.info(
        "available_time_slots_view: date=%s doctor_id=%s doctor_code=%s",
        date_str,
        doctor_id,
        doctor_code,
    )

    try:
        # Tool 컨텍스트 생성
        context = build_tool_context(session_id, metadata)

        # Tool 실행
        args = {
            "date": date_str,
        }
        if doctor_id:
            args["doctor_id"] = doctor_id
        if doctor_code:
            args["doctor_code"] = doctor_code

        result = execute_tool("available_time_slots", args, context)
        
        logger.info(
            "available_time_slots_view: result status=%s booked_times count=%s booked_times=%s",
            result.get("status"),
            len(result.get("booked_times", [])),
            result.get("booked_times", []),
        )

        return JsonResponse(result, status=200)
    except Exception as exc:
        logger.exception("available_time_slots_view: exception: %s", exc)
        # 에러 발생 시에도 빈 예약 목록 반환 (서버 연결이 끊어지지 않도록)
        return JsonResponse(
            {
                "status": "ok",  # 에러가 있어도 ok로 반환하여 연결 유지
                "date": date_str,
                "booked_times": [],
                "available_slots": [],
                "all_slots": [],
                "error": str(exc),
            },
            status=200,  # 200으로 반환하여 연결 유지
        )


@csrf_exempt
@require_GET
def my_appointments_view(request):
    """
    Flutter 마이페이지 "다가오는 일정"용: 환자별 예약 목록 조회.
    챗봇/병원 DB(patients_appointment)에서 patient_id(또는 patient_identifier)로 조회.
    Query: ?patient_id=xxx 또는 ?patient_identifier=xxx
    """
    patient_id = (
        request.GET.get("patient_id") or request.GET.get("patient_identifier") or ""
    ).strip()
    if not patient_id:
        return JsonResponse(
            {"error": "patient_id 또는 patient_identifier가 필요합니다."},
            status=400,
        )

    now = timezone.now()
    results = []

    if "hospital" not in connections.databases:
        return JsonResponse(results, safe=False)

    try:
        with connections["hospital"].cursor() as cursor:
            cursor.execute(
                """
                SELECT id, title, type, start_time, end_time, status, memo,
                       patient_identifier, patient_name, patient_gender, patient_age,
                       doctor_id, doctor_code, doctor_username, doctor_name, doctor_department,
                       created_at, updated_at
                FROM patients_appointment
                WHERE patient_identifier = %s
                  AND LOWER(COALESCE(status, '')) != 'cancelled'
                  AND start_time >= %s
                ORDER BY start_time ASC
                """,
                [patient_id, now],
            )
            rows = cursor.fetchall()
            columns = [col[0] for col in cursor.description]

        for row in rows:
            r = dict(zip(columns, row))
            start_time = r.get("start_time")
            end_time = r.get("end_time")
            doctor_id = r.get("doctor_id")
            doctor_name = r.get("doctor_name") or ""
            doctor_department = r.get("doctor_department") or ""
            doctor_display = f"{doctor_name} ({doctor_department})" if doctor_department else doctor_name

            results.append({
                "id": str(r.get("id", "")),
                "title": r.get("title") or "",
                "type": r.get("type") or "예약",
                "start_time": start_time.isoformat() if start_time else "",
                "end_time": end_time.isoformat() if end_time else None,
                "status": (r.get("status") or "scheduled").lower()
                if (r.get("status") or "").lower() in ("scheduled", "completed", "cancelled")
                else "scheduled",
                "memo": r.get("memo"),
                "patient_id": r.get("patient_identifier"),
                "patient_name": r.get("patient_name"),
                "patient_gender": r.get("patient_gender"),
                "patient_age": r.get("patient_age"),
                "doctor": int(doctor_id) if doctor_id is not None else 0,
                "doctor_username": r.get("doctor_username") or "",
                "doctor_name": doctor_name,
                "doctor_department": doctor_department,
                "doctor_display": doctor_display,
                "patient_display": r.get("patient_name"),
                "created_at": r.get("created_at").isoformat() if r.get("created_at") else None,
                "updated_at": r.get("updated_at").isoformat() if r.get("updated_at") else None,
            })
    except Exception as exc:
        logger.exception("my_appointments_view: %s", exc)
        return JsonResponse({"error": str(exc)}, status=500)

    return JsonResponse(results, safe=False)
