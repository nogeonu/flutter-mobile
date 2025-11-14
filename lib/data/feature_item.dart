import 'package:flutter/material.dart';

class FeatureItem {
  const FeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

const featureItems = [
  FeatureItem(
    id: 'chatbot',
    title: 'AI 상담',
    description: '병원 안내 챗봇',
    icon: Icons.chat_bubble_outline,
  ),
  FeatureItem(
    id: 'department_staff',
    title: '진료과 · 의료진',
    description: '전문의 정보 확인',
    icon: Icons.medical_services_outlined,
  ),
  FeatureItem(
    id: 'exam_history',
    title: '진료내역',
    description: '지난 진료 기록 조회',
    icon: Icons.receipt_long_outlined,
  ),
  FeatureItem(
    id: 'reservation',
    title: '진료예약',
    description: '예약 화면 준비 중',
    icon: Icons.calendar_today_outlined,
  ),
  FeatureItem(
    id: 'waiting_queue',
    title: '대기순번',
    description: '현재 순번 확인',
    icon: Icons.timer_outlined,
  ),
  FeatureItem(
    id: 'pharmacy',
    title: '약국 안내',
    description: '내원 환자 전용 약국',
    icon: Icons.local_pharmacy_outlined,
  ),
  FeatureItem(
    id: 'parking',
    title: '주차장',
    description: '실시간 주차 정보',
    icon: Icons.local_parking_outlined,
  ),
  FeatureItem(
    id: 'hospital_map',
    title: '병원 지도',
    description: '실시간 위치 확인',
    icon: Icons.map_outlined,
  ),
  FeatureItem(
    id: 'hospital_navigation',
    title: '병원 길 찾기',
    description: '내비게이션 경로 안내',
    icon: Icons.directions_walk_outlined,
  ),
];
