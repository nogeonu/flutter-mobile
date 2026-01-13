from __future__ import annotations

import logging
import re
from typing import Any, Dict, Optional

from django.utils import timezone

logger = logging.getLogger(__name__)

from chatbot.models import ChatMessage
from chatbot.services.common import AUTH_REQUIRED_REPLY
from chatbot.services.tooling import (
    ToolContext,
    execute_tool,
    _extract_department,
    _extract_doctor_name,
    _has_auth_context,
    _format_doctor_reply_name,
)
from chatbot.services.intents.keywords import (
    RESERVATION_HISTORY_CUES,
    RESCHEDULE_TIME_KEEP_CUES,
    DOCTOR_CHANGE_PROMPT,
    DOCTOR_SELECT_PROMPT,
    TIME_EXTRACT_PATTERN,
    DAY_ONLY_PATTERN,
    TIME_HINT_WORDS,
)
from chatbot.services.intents.classifiers import (
    has_booking_intent,
    has_reschedule_cue,
    has_doctor_change_cue,
    has_cancel_cue,
    is_wait_department_prompt,
    has_bulk_cancel_cue,
    is_doctor_change_prompt,
    is_doctor_select_prompt,
    is_reservation_summary,
    is_negative_reply,
    match_symptom_department,
)
from chatbot.services.flows import match_symptom_guide
from chatbot.services.extraction import (
    maybe_reject_closed_date,
    extract_day_only,
    extract_numeric_day,
    extract_day_only_list,
    extract_time_phrase,
    extract_numeric_hour,
    extract_date_phrase,
    is_multi_date_prompt,
    parse_date_only,
    build_date_same_month,
    build_date_from_base_day,
    merge_date_with_time,
    normalize_preferred_time,
    extract_selected_doctor_name,
    infer_recent_doctor_name,
    infer_recent_department,
    should_reschedule_from_summary,
    build_time_followup_message,
    has_specific_time,
    contains_asap,
)


def _build_tool_context(session_id: str | None, metadata: Dict[str, Any] | None) -> ToolContext:
    request_id = metadata.get("request_id") if isinstance(metadata, dict) else None
    user_id = None
    if isinstance(metadata, dict):
        user_id = (
            metadata.get("user_id")
            or metadata.get("patient_id")
            or metadata.get("patientId")
            or metadata.get("account_id")
            or metadata.get("auth_user_id")
        )
    return ToolContext(
        session_id=session_id,
        metadata=metadata,
        request_id=request_id,
        user_id=user_id,
    )


def _has_time_or_date_hint(text: str) -> bool:
    if not text:
        return False
    if TIME_EXTRACT_PATTERN.search(text):
        return True
    if DAY_ONLY_PATTERN.search(text):
        return True
    return any(word in text for word in TIME_HINT_WORDS)


def is_negative_only_reply(query: str, metadata: Dict[str, Any] | None) -> bool:
    if not is_negative_reply(query):
        return False
    if _has_time_or_date_hint(query):
        return False
    if _extract_department(query, metadata):
        return False
    if match_symptom_department(query) or match_symptom_guide(query):
        return False
    if _extract_doctor_name(query, metadata):
        return False
    if has_reschedule_cue(query) or has_cancel_cue(query) or has_doctor_change_cue(query):
        return False
    return True


def handle_reservation_followup(
    query: str,
    session_id: str | None,
    metadata: Dict[str, Any] | None,
) -> dict | None:
    if not session_id:
        return None
    
    # 이전 메시지 확인 (의료진 선택 프롬프트 체크를 위해)
    last_message = (
        ChatMessage.objects.filter(session_id=session_id)
        .order_by("-created_at")
        .first()
    )
    last_bot_answer = last_message.bot_answer or "" if last_message else ""
    
    # 명확한 예약 의도가 있는지 먼저 체크
    # 예약 관련 키워드가 없으면 바로 None 반환 (일반 질문 처리)
    reservation_keywords = [
        "예약", "진료", "의사", "선생님", "변경", "취소", "날짜", "시간",
        "예약내역", "예약 내역", "예약이력", "예약 이력", "예약조회", "예약 조회",
        "예약확인", "예약 확인", "예약시간", "예약 시간", "예약일정", "예약 일정",
        "예약스케줄", "예약 스케줄", "예약취소", "예약 취소", "예약변경", "예약 변경"
    ]
    
    # 버튼 클릭 감지: 이전 메시지에 "권장드립니다"가 있고, 현재 메시지가 진료과 이름만 있는 경우
    # (예: "외과", "호흡기내과"만 전송된 경우)
    # 의료진 이름 추출 전에 먼저 체크하여 진료과 이름을 의료진 이름으로 잘못 인식하는 것을 방지
    department_only = _extract_department(query, metadata)
    
    # 진료과 이름 목록 (의료진 이름과 구분하기 위해)
    department_names = ["외과", "호흡기내과", "내과", "소아과", "산부인과", "정형외과", "신경과", "정신과", "안과", "이비인후과", "피부과", "비뇨의학과", "영상의학과", "방사선과", "원무과"]
    
    # 버튼 클릭 컨텍스트: 진료과 이름만 입력되고, 이전 메시지에 권장 메시지가 있는 경우
    # 더 단순하고 확실한 감지 로직
    query_stripped = query.strip()
    
    # 진료과 이름만 입력되었는지 확인 (더 유연한 체크)
    is_department_name_only = (
        department_only 
        and len(query_stripped) <= 15
        and not any(keyword in query for keyword in reservation_keywords)
        and (
            query_stripped in department_names  # 정확히 진료과 이름 목록에 있거나
            or query_stripped == department_only  # 추출된 진료과와 일치하거나
            or (len(query_stripped) <= 10 and department_only in query_stripped)  # 진료과 이름이 포함된 경우
        )
    )
    
    # 버튼 클릭 감지 키워드 확장
    button_click_keywords = [
        "권장드립니다", "예약하기", "진료를 권장", "진료를", "권장", "예약", "진료"
    ]
    has_button_keyword = any(keyword in last_bot_answer for keyword in button_click_keywords) if last_bot_answer else False
    
    # 버튼 클릭 컨텍스트 감지 (더 관대한 조건)
    has_button_click_context = (
        is_department_name_only
        and last_bot_answer
        and (
            has_button_keyword  # 버튼 관련 키워드가 있거나
            or len(last_bot_answer) > 30  # 이전 메시지가 충분히 긴 경우 (권장 메시지일 가능성)
        )
    )
    
    # 로깅 추가
    logger.info(
        f"[reservation_flow] Button click context check: "
        f"department_only={department_only}, "
        f"is_department_name_only={is_department_name_only}, "
        f"has_button_keyword={has_button_keyword}, "
        f"last_bot_answer={last_bot_answer[:80] if last_bot_answer else None}, "
        f"query={query}, "
        f"query_stripped={query_stripped}, "
        f"has_button_click_context={has_button_click_context}"
    )
    
    # 버튼 클릭 컨텍스트일 때는 의료진 이름 추출을 건너뛰고 바로 의료진 목록 조회
    if has_button_click_context:
        logger.info(f"[reservation_flow] Button click detected! Showing doctor list for {department_only}")
        department = department_only
        if not department:
            return {"reply": "예약을 위해 진료과를 알려주세요.", "sources": []}
        if not _has_auth_context(metadata):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
        tool_context = _build_tool_context(session_id, metadata)
        doctor_result = execute_tool("doctor_list", {"department": department}, tool_context)
        if isinstance(doctor_result, dict) and doctor_result.get("status") in {"not_found", "error"}:
            return {
                "reply": doctor_result.get("reply_text")
                or "해당 진료과 의료진 정보를 찾지 못했습니다. 원하시면 진료과명을 정확히 알려주세요.",
                "sources": [],
            }
        payload = {
            "reply": f"{department} 의료진을 선택해 주세요. 선택 후 예약을 진행합니다.",
            "sources": [],
        }
        if isinstance(doctor_result, dict) and doctor_result.get("table"):
            payload["table"] = doctor_result["table"]
        return payload
    
    # 의료진 이름 추출 시도 (버튼 클릭 컨텍스트가 아닐 때만)
    doctor_name = extract_selected_doctor_name(query, metadata) or _extract_doctor_name(query, metadata)
    
    # 명확한 예약 의도가 있는지 체크
    # 의료진 이름이 있고 이전 메시지에 "의료진"과 "선택" 키워드가 있으면 예약 의도로 간주
    has_doctor_select_context = (
        doctor_name 
        and last_bot_answer 
        and ("의료진" in last_bot_answer or "의사" in last_bot_answer)
        and ("선택" in last_bot_answer)
    )
    
    has_reservation_intent = (
        has_booking_intent(query)
        or any(cue in query for cue in RESERVATION_HISTORY_CUES)
        or has_cancel_cue(query)
        or has_reschedule_cue(query)
        or has_doctor_change_cue(query)
        or any(keyword in query for keyword in reservation_keywords)
        or is_doctor_select_prompt(last_bot_answer)  # 의료진 선택 프롬프트
        or has_doctor_select_context  # 의료진 이름 + 선택 컨텍스트
        or has_button_click_context  # 버튼 클릭 컨텍스트
    )
    
    # 예약 의도가 없으면 이전 메시지 체크도 하지 않음
    if not has_reservation_intent:
        return None
    
    department: str | None = None
    preferred_time: str | None = None
    date_hint: str | None = None
    asap = False
    if not _has_auth_context(metadata):
        if (
            any(cue in query for cue in RESERVATION_HISTORY_CUES)
            or has_cancel_cue(query)
            or has_reschedule_cue(query)
            or has_doctor_change_cue(query)
        ):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
    if has_booking_intent(query):
        closed_reply = maybe_reject_closed_date(query)
        if closed_reply:
            return {"reply": closed_reply, "sources": []}
    if any(cue in query for cue in RESERVATION_HISTORY_CUES):
        if not _has_auth_context(metadata):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
        has_time = _has_time_or_date_hint(query) or any(
            marker in query for marker in RESCHEDULE_TIME_KEEP_CUES
        )
        has_explicit_department = _extract_department(query, None) is not None
        if not (
            has_time
            or has_reschedule_cue(query)
            or has_doctor_change_cue(query)
            or has_explicit_department
        ):
            tool_context = _build_tool_context(session_id, metadata)
            result = execute_tool("reservation_history", {}, tool_context)
            if isinstance(result, dict) and result.get("reply_text"):
                payload = {"reply": result["reply_text"], "sources": []}
                if result.get("table"):
                    payload["table"] = result["table"]
                return payload
            if isinstance(result, dict) and result.get("status") == "error":
                return {
                    "reply": "현재 예약 내역을 확인하기 어렵습니다. 잠시 후 다시 시도해 주세요.",
                    "sources": [],
                }
            return None
    
    if not last_message:
        return None
    
    # 버튼 클릭 컨텍스트를 가장 먼저 체크 (의료진 이름 추출 전에 처리)
    if has_button_click_context:
        department = _extract_department(query, metadata)
        if not department:
            return {"reply": "예약을 위해 진료과를 알려주세요.", "sources": []}
        if not _has_auth_context(metadata):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
        tool_context = _build_tool_context(session_id, metadata)
        doctor_result = execute_tool("doctor_list", {"department": department}, tool_context)
        if isinstance(doctor_result, dict) and doctor_result.get("status") in {"not_found", "error"}:
            return {
                "reply": doctor_result.get("reply_text")
                or "해당 진료과 의료진 정보를 찾지 못했습니다. 원하시면 진료과명을 정확히 알려주세요.",
                "sources": [],
            }
        payload = {
            "reply": f"{department} 의료진을 선택해 주세요. 선택 후 예약을 진행합니다.",
            "sources": [],
        }
        if isinstance(doctor_result, dict) and doctor_result.get("table"):
            payload["table"] = doctor_result["table"]
        return payload
    
    # 의료진 선택 프롬프트 체크를 수행 (의료진 이름만 전송된 경우 처리)
    if is_doctor_select_prompt(last_bot_answer) or has_doctor_select_context:
        if not _has_auth_context(metadata):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
        if has_cancel_cue(query):
            tool_context = _build_tool_context(session_id, metadata)
            cancel_args = {"cancel_all": True} if has_bulk_cancel_cue(query) else {}
            cancel_args["cancel_text"] = query
            result = execute_tool("reservation_cancel", cancel_args, tool_context)
            if isinstance(result, dict) and result.get("reply_text"):
                return {"reply": result["reply_text"], "sources": []}
            if isinstance(result, dict) and result.get("status") == "not_found":
                return {
                    "reply": "취소할 예약을 찾지 못했습니다. 예약 번호나 연락처를 알려주세요.",
                    "sources": [],
                }
            if isinstance(result, dict) and result.get("status") == "error":
                return {
                    "reply": "현재 시스템에서 확인이 어렵습니다. 예약 번호나 연락처를 알려주시면 확인해 드리겠습니다.",
                    "sources": [],
                }
        if is_negative_only_reply(query, metadata):
            return {"reply": "알겠습니다. 필요하시면 다시 말씀해 주세요.", "sources": []}
        # 의료진 선택 후 날짜/시간 요청 로직으로 진행 (아래 코드 계속)
    
    # is_wait_department_prompt 체크는 명확한 예약 의도가 있을 때만 실행
    # 현재 질문에 예약 관련 키워드가 없으면 이전 메시지 체크도 하지 않음
    if is_wait_department_prompt(last_bot_answer) and has_reservation_intent:
        department = _extract_department(query, metadata)
        if department:
            tool_context = _build_tool_context(session_id, metadata)
            result = execute_tool("wait_status", {"department": department}, tool_context)
            if isinstance(result, dict) and result.get("reply_text"):
                return {"reply": result["reply_text"], "sources": []}
        return {"reply": "대기 현황을 확인할 진료과를 알려주세요.", "sources": []}
    if (
        is_negative_only_reply(query, metadata)
        and any(
            marker in last_bot_answer
            for marker in ["지난 날짜나 시간", "오늘 이후의 날짜와 시간"]
        )
    ):
        return {"reply": "알겠습니다. 필요하시면 다시 말씀해 주세요.", "sources": []}
    if is_multi_date_prompt(last_bot_answer):
        if is_negative_only_reply(query, metadata):
            return {"reply": "알겠습니다. 필요하시면 다시 말씀해 주세요.", "sources": []}
        day_only = extract_day_only(query) or extract_numeric_day(query)
        if not day_only:
            return {
                "reply": "여러 날짜가 있습니다. 예약할 날짜를 하나만 알려주세요.",
                "sources": [],
            }
        recent_messages = list(
            ChatMessage.objects.filter(session_id=session_id).order_by("-created_at")[:6]
        )
        day_candidates: list[int] = []
        for text in [m.user_question for m in recent_messages]:
            day_candidates.extend(extract_day_only_list(text))
        if day_only and day_only not in day_candidates:
            day_candidates.append(day_only)
        day_candidates = sorted(set(day_candidates))
        date_hint = None
        for text in [m.user_question for m in recent_messages] + [m.bot_answer for m in recent_messages]:
            date_hint = extract_date_phrase(text)
            if date_hint:
                break
        base_date = parse_date_only(date_hint) if date_hint else timezone.localdate()
        adjusted = (
            build_date_same_month(base_date, day_only)
            or build_date_from_base_day(base_date, day_only)
        ) if base_date else None
        if adjusted:
            date_hint = f"{adjusted.month}월 {adjusted.day}일"
        preferred_time = extract_time_phrase(query)
        if not preferred_time:
            numeric_hour = extract_numeric_hour(query)
            if numeric_hour is not None:
                preferred_time = f"{numeric_hour}시"
        if not preferred_time:
            for text in [m.user_question for m in recent_messages]:
                preferred_time = extract_time_phrase(text)
                if not preferred_time:
                    numeric_hour = extract_numeric_hour(text)
                    if numeric_hour is not None:
                        preferred_time = f"{numeric_hour}시"
                if preferred_time:
                    break
        preferred_time = merge_date_with_time(preferred_time, date_hint)
        preferred_time = normalize_preferred_time(preferred_time, False)
        department = _extract_department(query, metadata) or infer_recent_department(session_id)
        if not department:
            return {"reply": "예약을 위해 진료과를 알려주세요.", "sources": []}
        if not _has_auth_context(metadata):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
        doctor_name = extract_selected_doctor_name(query, metadata) or _extract_doctor_name(query, metadata)
        if not doctor_name:
            for message in recent_messages:
                for text in [message.user_question, message.bot_answer]:
                    doctor_name = _extract_doctor_name(text, metadata)
                    if doctor_name:
                        break
                if doctor_name:
                    break
        if not doctor_name:
            doctor_name = infer_recent_doctor_name(session_id)
        if not doctor_name:
            tool_context = _build_tool_context(session_id, metadata)
            doctor_result = execute_tool("doctor_list", {"department": department}, tool_context)
            payload = {
                "reply": f"{department} 의료진을 선택해 주세요. 선택 후 예약을 진행합니다.",
                "sources": [],
            }
            if isinstance(doctor_result, dict) and doctor_result.get("table"):
                payload["table"] = doctor_result["table"]
            return payload
        if not preferred_time:
            return {
                "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. 희망 날짜/시간을 알려주세요.",
                "sources": [],
            }
        if not has_specific_time(preferred_time):
            return {
                "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. {build_time_followup_message(preferred_time)}",
                "sources": [],
            }
        tool_context = _build_tool_context(session_id, metadata)
        result = execute_tool(
            "reservation_create",
            {"department": department, "preferred_time": preferred_time, "doctor_name": doctor_name},
            tool_context,
        )
        if isinstance(result, dict) and result.get("reply_text"):
            reply_text = result["reply_text"]
            remaining_days = [d for d in day_candidates if d != day_only]
            if remaining_days:
                remain_text = ", ".join(f"{day}일" for day in remaining_days)
                reply_text = (
                    f"{reply_text} 남은 날짜({remain_text})도 예약할까요? 원하시면 날짜만 알려주세요."
                )
            payload = {"reply": reply_text, "sources": []}
            if result.get("table"):
                payload["table"] = result["table"]
            return payload
        if isinstance(result, dict) and result.get("status") == "ok":
            payload = {
                "reply": f"{doctor_name} 의사로 예약이 완료되었습니다.\n{department} 진료 예약 요청이 접수되었습니다.\n희망 일정은 {preferred_time}입니다.",
                "sources": [],
            }
            if result.get("table"):
                payload["table"] = result["table"]
            return payload
        if isinstance(result, dict) and result.get("status") == "error":
            return {
                "reply": "현재 예약을 처리하기 어렵습니다. 잠시 후 다시 시도해 주세요.",
                "sources": [],
            }
    if not _has_auth_context(metadata):
        if is_doctor_change_prompt(last_bot_answer) or is_reservation_summary(last_bot_answer):
            return {"reply": AUTH_REQUIRED_REPLY, "sources": []}
    if is_doctor_change_prompt(last_bot_answer):
        if is_negative_only_reply(query, metadata):
            return {"reply": "알겠습니다. 필요하시면 다시 말씀해 주세요.", "sources": []}
        tool_context = _build_tool_context(session_id, metadata)
        doctor_name = extract_selected_doctor_name(query, metadata)
        if not doctor_name:
            department = _extract_department(query, metadata) or infer_recent_department(session_id)
            prompt = f"{department} {DOCTOR_CHANGE_PROMPT}" if department else DOCTOR_CHANGE_PROMPT
            return {"reply": prompt, "sources": []}
        result = execute_tool(
            "reservation_reschedule",
            {"doctor_name": doctor_name},
            tool_context,
        )
        if isinstance(result, dict) and result.get("reply_text"):
            payload = {"reply": result["reply_text"], "sources": []}
            if result.get("table"):
                payload["table"] = result["table"]
            return payload
        if isinstance(result, dict) and result.get("status") == "not_found":
            return {
                "reply": "변경할 예약을 찾지 못했습니다. 예약 번호나 연락처를 알려주세요.",
                "sources": [],
            }
        if isinstance(result, dict) and result.get("status") == "error":
            return {
                "reply": "현재 예약 변경을 처리하기 어렵습니다. 잠시 후 다시 시도해 주세요.",
                "sources": [],
            }
    # 의료진 선택 프롬프트 체크는 위에서 이미 처리했으므로 여기서는 제거
    # 아래 로직은 의료진 선택 후 날짜/시간 요청 처리
    tool_context = _build_tool_context(session_id, metadata)
    
    # 의료진 선택 프롬프트가 있었던 경우 의료진 이름 재확인
    if is_doctor_select_prompt(last_bot_answer) or has_doctor_select_context:
        # 의료진 이름이 이미 추출되었는지 확인
        if not doctor_name:
            doctor_name = extract_selected_doctor_name(query, metadata) or _extract_doctor_name(query, metadata)
        
        if not doctor_name:
            department = (
                _extract_department(query, metadata)
                or _extract_department(last_bot_answer, None)
                or infer_recent_department(session_id)
            )
            doctor_result = None
            if department:
                doctor_result = execute_tool(
                    "doctor_list",
                    {"department": department},
                    tool_context,
                )
                if isinstance(doctor_result, dict) and doctor_result.get("status") in {"not_found", "error"}:
                    return {
                        "reply": doctor_result.get("reply_text")
                        or "해당 진료과 의료진 정보를 찾지 못했습니다. 원하시면 진료과명을 정확히 알려주세요.",
                        "sources": [],
                    }
            reply_text = f"{department} {DOCTOR_SELECT_PROMPT}" if department else DOCTOR_SELECT_PROMPT
            payload = {"reply": reply_text, "sources": []}
            if isinstance(doctor_result, dict) and doctor_result.get("table"):
                payload["table"] = doctor_result["table"]
            return payload
        
        # 의료진 이름이 있으면 바로 날짜/시간 요청으로 넘어감
        department = (
            _extract_department(query, metadata)
            or _extract_department(last_bot_answer, None)
            or infer_recent_department(session_id)
        )
        preferred_time = extract_time_phrase(query)
        if not preferred_time:
            numeric_hour = extract_numeric_hour(query)
            if numeric_hour is not None:
                preferred_time = f"{numeric_hour}시"
        asap = contains_asap(query)
        
        if not preferred_time:
            return {
                "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. 희망 날짜/시간을 알려주세요.",
                "sources": [],
            }
        
        # 날짜/시간이 있으면 예약 진행
        recent_messages = list(
            ChatMessage.objects.filter(session_id=session_id).order_by("-created_at")[:5]
        )
        if not department:
            search_texts = [last_message.bot_answer, last_message.user_question]
            search_texts.extend(m.user_question for m in recent_messages)
            for text in search_texts:
                if not text:
                    continue
                department = _extract_department(text, None) or match_symptom_department(text)
                if department:
                    break
        if not preferred_time:
            for text in [last_message.user_question] + [m.user_question for m in recent_messages]:
                if not text:
                    continue
                preferred_time = extract_time_phrase(text)
                if not preferred_time:
                    numeric_hour = extract_numeric_hour(text)
                    if numeric_hour is not None:
                        preferred_time = f"{numeric_hour}시"
                asap = asap or contains_asap(text)
                if preferred_time:
                    break
        date_hint = extract_date_phrase(last_bot_answer)
        if not date_hint:
            search_texts = [last_message.user_question] + [m.user_question for m in recent_messages]
            search_texts.extend(m.bot_answer for m in recent_messages)
            for text in search_texts:
                date_hint = extract_date_phrase(text)
                if date_hint:
                    break
        day_only = extract_day_only(query)
        if not day_only and is_multi_date_prompt(last_bot_answer):
            day_only = extract_numeric_day(query)
        day_candidates = []
        for text in [last_message.user_question] + [m.user_question for m in recent_messages]:
            day_candidates.extend(extract_day_only_list(text))
        day_candidates = sorted(set(day_candidates))
        if not date_hint and len(day_candidates) > 1 and not day_only:
            return {
                "reply": "여러 날짜가 있습니다. 예약할 날짜를 하나만 알려주세요.",
                "sources": [],
            }
        if not date_hint and not day_only and len(day_candidates) == 1:
            day_only = day_candidates[0]
        if day_only and not extract_date_phrase(query):
            base_date = parse_date_only(date_hint) if date_hint else timezone.localdate()
            adjusted = (
                build_date_same_month(base_date, day_only)
                or build_date_from_base_day(base_date, day_only)
            ) if base_date else None
            if adjusted:
                date_hint = f"{adjusted.month}월 {adjusted.day}일"
                if preferred_time and extract_date_phrase(preferred_time):
                    preferred_time = date_hint
                else:
                    preferred_time = merge_date_with_time(preferred_time, date_hint)
                    if not preferred_time:
                        preferred_time = date_hint
        preferred_time = merge_date_with_time(preferred_time, date_hint)
        preferred_time = normalize_preferred_time(preferred_time, asap)
        closed_reply = maybe_reject_closed_date(preferred_time or "")
        if closed_reply:
            return {"reply": closed_reply, "sources": []}
        if not department:
            return {"reply": "예약을 위해 진료과를 알려주세요.", "sources": []}
        if not preferred_time:
            return {
                "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. 희망 날짜/시간을 알려주세요.",
                "sources": [],
            }
        if not has_specific_time(preferred_time) and not asap:
            return {
                "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. {build_time_followup_message(preferred_time)}",
                "sources": [],
            }
        result = execute_tool(
            "reservation_create",
            {"department": department, "preferred_time": preferred_time, "doctor_name": doctor_name},
            tool_context,
        )
        if isinstance(result, dict):
            if result.get("reply_text"):
                payload = {"reply": result["reply_text"], "sources": []}
                if result.get("table"):
                    payload["table"] = result["table"]
                return payload
            if result.get("status") == "ok":
                payload = {
                    "reply": f"{doctor_name} 의사로 예약이 완료되었습니다.\n{department} 진료 예약 요청이 접수되었습니다.\n희망 일정은 {preferred_time}입니다.",
                    "sources": [],
                }
                if result.get("table"):
                    payload["table"] = result["table"]
                return payload
            if result.get("status") == "not_found":
                return {
                    "reply": "요청하신 의료진 정보를 찾지 못했습니다. 의료진 이름을 다시 알려주세요.",
                    "sources": [],
                }
            if result.get("status") == "error":
                return {
                    "reply": "현재 예약을 처리하기 어렵습니다. 잠시 후 다시 시도해 주세요.",
                    "sources": [],
                }
        return {
            "reply": "예약 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.",
            "sources": [],
        }
    if is_reservation_summary(last_bot_answer):
        tool_context = _build_tool_context(session_id, metadata)
        auto_reschedule = should_reschedule_from_summary(query, metadata)
        if has_cancel_cue(query):
            cancel_args = {"cancel_all": True} if has_bulk_cancel_cue(query) else {}
            cancel_args["cancel_text"] = query
            result = execute_tool("reservation_cancel", cancel_args, tool_context)
            if isinstance(result, dict) and result.get("reply_text"):
                return {"reply": result["reply_text"], "sources": []}
            if isinstance(result, dict) and result.get("status") == "not_found":
                return {"reply": "취소할 예약을 찾지 못했습니다. 예약 번호나 연락처를 알려주세요.", "sources": []}
            if isinstance(result, dict) and result.get("status") == "error":
                return {
                    "reply": "현재 시스템에서 확인이 어렵습니다. 예약 번호나 연락처를 알려주시면 확인해 드리겠습니다.",
                    "sources": [],
                }
        if has_reschedule_cue(query) or auto_reschedule:
            new_department = _extract_department(query, metadata)
            has_time = _has_time_or_date_hint(query) or any(
                marker in query for marker in RESCHEDULE_TIME_KEEP_CUES
            )
            if not has_time and not new_department:
                return {
                    "reply": "예약 변경을 위해 변경할 날짜/시간이나 진료과를 알려주세요.",
                    "sources": [],
                }
            reschedule_args: Dict[str, Any] = {}
            if has_time:
                new_time_text = query
                if _has_time_or_date_hint(query):
                    time_phrase = extract_time_phrase(query)
                    if time_phrase:
                        new_time_text = time_phrase
                recent_messages = list(
                    ChatMessage.objects.filter(session_id=session_id).order_by("-created_at")[:5]
                )
                date_hint = extract_date_phrase(last_bot_answer)
                if not date_hint:
                    search_texts = [last_message.user_question] + [m.user_question for m in recent_messages]
                    search_texts.extend(m.bot_answer for m in recent_messages)
                    for text in search_texts:
                        date_hint = extract_date_phrase(text)
                        if date_hint:
                            break
                day_only = extract_day_only(query)
                if not day_only and is_multi_date_prompt(last_bot_answer):
                    day_only = extract_numeric_day(query)
                day_candidates = []
                for text in [last_message.user_question] + [m.user_question for m in recent_messages]:
                    day_candidates.extend(extract_day_only_list(text))
                day_candidates = sorted(set(day_candidates))
                if not date_hint and len(day_candidates) > 1 and not day_only:
                    return {
                        "reply": "여러 날짜가 있습니다. 예약할 날짜를 하나만 알려주세요.",
                        "sources": [],
                    }
                if not date_hint and not day_only and len(day_candidates) == 1:
                    day_only = day_candidates[0]
                if day_only and not extract_date_phrase(query):
                    base_date = parse_date_only(date_hint) if date_hint else timezone.localdate()
                    adjusted = (
                        build_date_same_month(base_date, day_only)
                        or build_date_from_base_day(base_date, day_only)
                    ) if base_date else None
                    if adjusted:
                        date_hint = f"{adjusted.month}월 {adjusted.day}일"
                        if extract_date_phrase(new_time_text or ""):
                            new_time_text = date_hint
                        else:
                            new_time_text = merge_date_with_time(new_time_text, date_hint)
                            if not new_time_text:
                                new_time_text = date_hint
                new_time_text = merge_date_with_time(new_time_text, date_hint)
                reschedule_args["new_time"] = normalize_preferred_time(new_time_text, False)
            if new_department:
                reschedule_args["new_department"] = new_department
            if not reschedule_args:
                return {
                    "reply": "예약 변경을 위해 변경할 날짜/시간이나 진료과를 알려주세요.",
                    "sources": [],
                }
            result = execute_tool("reservation_reschedule", reschedule_args, tool_context)
            if isinstance(result, dict) and result.get("reply_text"):
                return {"reply": result["reply_text"], "sources": []}
            if isinstance(result, dict) and result.get("status") == "not_found":
                return {
                    "reply": "변경할 예약을 찾지 못했습니다. 예약 번호나 연락처를 알려주세요.",
                    "sources": [],
                }
            if isinstance(result, dict) and result.get("status") == "error":
                return {
                    "reply": "현재 예약 변경을 처리하기 어렵습니다. 잠시 후 다시 시도해 주세요.",
                    "sources": [],
                }
    
    # Fallback to general reservation logic if no specific prompt context matched
    if department is None:
        department = _extract_department(query, metadata) or infer_recent_department(session_id)
    if preferred_time is None:
        preferred_time = extract_time_phrase(query)
        if not preferred_time:
            numeric_hour = extract_numeric_hour(query)
            if numeric_hour is not None:
                preferred_time = f"{numeric_hour}시"
    if not date_hint:
        date_hint = extract_date_phrase(query) or extract_date_phrase(last_bot_answer)
    day_only = extract_day_only(query)
    if day_only and not extract_date_phrase(query):
        base_date = parse_date_only(date_hint) if date_hint else timezone.localdate()
        adjusted = (
            build_date_same_month(base_date, day_only)
            or build_date_from_base_day(base_date, day_only)
        ) if base_date else None
        if adjusted:
            date_hint = f"{adjusted.month}월 {adjusted.day}일"
            if preferred_time and extract_date_phrase(preferred_time):
                preferred_time = date_hint
            else:
                preferred_time = merge_date_with_time(preferred_time, date_hint)
                if not preferred_time:
                    preferred_time = date_hint
    preferred_time = merge_date_with_time(preferred_time, date_hint)
    asap = asap or contains_asap(query)
    preferred_time = normalize_preferred_time(preferred_time, asap)
    closed_reply = maybe_reject_closed_date(preferred_time or "")
    if closed_reply:
        return {"reply": closed_reply, "sources": []}

    if not department:
        return {"reply": "예약을 위해 진료과를 알려주세요.", "sources": []}
    
    # 버튼 클릭 컨텍스트일 때는 의료진 이름 추출을 건너뛰고 바로 의료진 목록 조회
    if has_button_click_context:
        tool_context = _build_tool_context(session_id, metadata)
        doctor_result = execute_tool("doctor_list", {"department": department}, tool_context)
        if isinstance(doctor_result, dict) and doctor_result.get("status") in {"not_found", "error"}:
            return {
                "reply": doctor_result.get("reply_text")
                or "해당 진료과 의료진 정보를 찾지 못했습니다. 원하시면 진료과명을 정확히 알려주세요.",
                "sources": [],
            }
        payload = {
            "reply": f"{department} 의료진을 선택해 주세요. 선택 후 예약을 진행합니다.",
            "sources": [],
        }
        if isinstance(doctor_result, dict) and doctor_result.get("table"):
            payload["table"] = doctor_result["table"]
        return payload
    
    # 진료과는 있지만 의료진이 선택되지 않은 경우 → 의료진 목록 먼저 표시
    doctor_name = _extract_doctor_name(query, metadata)
    
    # 진료과 이름을 의료진 이름으로 잘못 인식하는 경우 방지
    # 현재 쿼리가 진료과 이름만 있는 경우 (예: "외과", "호흡기내과") 의료진 이름으로 간주하지 않음
    if doctor_name:
        # 진료과 이름 목록
        department_names = ["외과", "호흡기내과", "내과", "소아과", "산부인과", "정형외과", "신경과", "정신과", "안과", "이비인후과", "피부과", "비뇨의학과", "영상의학과", "방사선과", "원무과"]
        # 의료진 이름이 진료과 이름과 동일하면 None으로 처리 (의료진 목록 조회하도록)
        if doctor_name in department_names or doctor_name == department:
            doctor_name = None
    
    if not doctor_name:
        # 이전 메시지에서 의료진 이름 추출 시도
        department_names = ["외과", "호흡기내과", "내과", "소아과", "산부인과", "정형외과", "신경과", "정신과", "안과", "이비인후과", "피부과", "비뇨의학과", "영상의학과", "방사선과", "원무과"]
        if last_message:
            for text in [last_message.user_question, last_message.bot_answer]:
                extracted_name = _extract_doctor_name(text, metadata)
                # 진료과 이름이 아닌 경우만 의료진 이름으로 인정
                if extracted_name and extracted_name not in department_names and extracted_name != department:
                    doctor_name = extracted_name
                    break
        if not doctor_name:
            inferred_name = infer_recent_doctor_name(session_id)
            # 추론된 이름도 진료과 이름이 아닌 경우만 인정
            if inferred_name and inferred_name not in department_names and inferred_name != department:
                doctor_name = inferred_name
    
    # 의료진이 없으면 의료진 목록 먼저 표시
    if not doctor_name:
        tool_context = _build_tool_context(session_id, metadata)
        doctor_result = execute_tool("doctor_list", {"department": department}, tool_context)
        if isinstance(doctor_result, dict) and doctor_result.get("status") in {"not_found", "error"}:
            return {
                "reply": doctor_result.get("reply_text")
                or "해당 진료과 의료진 정보를 찾지 못했습니다. 원하시면 진료과명을 정확히 알려주세요.",
                "sources": [],
            }
        payload = {
            "reply": f"{department} 의료진을 선택해 주세요. 선택 후 예약을 진행합니다.",
            "sources": [],
        }
        if isinstance(doctor_result, dict) and doctor_result.get("table"):
            payload["table"] = doctor_result["table"]
        return payload
    
    # 의료진은 선택되었지만 날짜/시간이 없는 경우 → 날짜/시간 요청
    if not preferred_time:
        return {
            "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. 희망 날짜/시간을 알려주세요.",
            "sources": [],
        }
    if not has_specific_time(preferred_time):
        if not asap:
            return {
                "reply": f"{doctor_name} 의료진으로 예약을 진행합니다. {build_time_followup_message(preferred_time)}",
                "sources": [],
            }

    tool_context = _build_tool_context(session_id, metadata)
    result = execute_tool(
        "reservation_create",
        {
            "department": department,
            "preferred_time": preferred_time,
            "doctor_name": doctor_name,
        },
        tool_context,
    )
    if isinstance(result, dict):
        if result.get("reply_text"):
            return {"reply": result["reply_text"], "sources": []}
        if result.get("status") == "ok":
            return {
                "reply": (
                    f"{department} 진료 예약 요청이 접수되었습니다. "
                    f"희망 일정은 {preferred_time}입니다."
                ),
                "sources": [],
            }
        if result.get("status") == "error":
            return {
                "reply": "현재 예약을 처리하기 어렵습니다. 잠시 후 다시 시도해 주세요.",
                "sources": [],
            }
    return {
        "reply": "예약 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.",
        "sources": [],
    }
