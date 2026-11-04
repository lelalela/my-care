import 'package:flutter/material.dart';

/// 6대 대사 질환 정의 및 임상 메타데이터
enum ConditionType {
  prediabetes(
    id: 'prediabetes',
    name: '전당뇨',
    badge: '식후 골든타임',
    description: '식후 30~60분 시점 걷기로 혈당 스파이크 억제',
    clinicalFocus: '하체 대근육(허벅지)을 활용해 인슐린 비의존성 포도당 흡수를 촉진합니다.',
    icon: Icons.bloodtype_outlined,
  ),
  fattyLiver(
    id: 'fatty_liver',
    name: '지방간',
    badge: '내장지방 연소',
    description: '40분 이상 중등도 유산소로 간 내 지방산 산화',
    clinicalFocus: '내장지방 감소를 위해 최소 30~45분 지속 가능한 110 SPM 속도를 유지합니다.',
    icon: Icons.monitor_heart_outlined,
  ),
  hypertension(
    id: 'hypertension',
    name: '고혈압',
    badge: '발살바 호흡 금기',
    description: '숨 참지 않는 부드러운 저중량 다반복 머신 운동',
    clinicalFocus: '혈압 급상승을 막기 위해 무거운 프리웨이트 대신 머신과 지속 호흡을 권장합니다.',
    icon: Icons.favorite_outline,
  ),
  dyslipidemia(
    id: 'dyslipidemia',
    name: '고지혈증',
    badge: '지질 개선',
    description: 'HDL 증가와 중성지방 감소를 위한 45분 이상 유산소',
    clinicalFocus: '지방 대사 효소 활성화를 위해 충분한 시간의 지속 유산소가 핵심입니다.',
    icon: Icons.water_drop_outlined,
  ),
  obesity(
    id: 'obesity',
    name: '비만/복부비만',
    badge: '관절 보호',
    description: '무릎 관절 부담을 줄이는 충격 분산 유산소',
    clinicalFocus: '과체중으로 인한 무릎·발목 관절을 보호하며 점진적으로 활동량을 늘립니다.',
    icon: Icons.accessibility_new_outlined,
  ),
  gout(
    id: 'gout',
    name: '통풍',
    badge: '젖산 억제',
    description: '요산 배출을 돕는 저~중등도 운동 (고강도 금기)',
    clinicalFocus: '과도한 젖산 축적으로 인한 요산 배출 방해를 막기 위해 고강도 무산소를 피합니다.',
    icon: Icons.healing_outlined,
  );

  const ConditionType({
    required this.id,
    required this.name,
    required this.badge,
    required this.description,
    required this.clinicalFocus,
    required this.icon,
  });

  final String id;
  final String name;
  final String badge;
  final String description;
  final String clinicalFocus;
  final IconData icon;
}

/// 운동 선호 환경
enum ExerciseEnvironment {
  all(id: 'all', label: '전체 (어디서나)', icon: Icons.public_outlined),
  gym(id: 'gym', label: '헬스장 (기구 중심)', icon: Icons.fitness_center_outlined),
  home(id: 'home', label: '홈트레이닝 (맨몸)', icon: Icons.home_outlined);

  const ExerciseEnvironment({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}
