import 'dart:math';

class FoodSuggestion {
  final String emoji;
  final String name;
  final Map<String, String> nutritionFacts;
  final String tip;

  const FoodSuggestion({
    required this.emoji,
    required this.name,
    required this.nutritionFacts,
    required this.tip,
  });
}

class HealthInfoService {
  final Random _random = Random();

  static const List<FoodSuggestion> _fruitSuggestions = [
    FoodSuggestion(
      emoji: '🍎',
      name: '사과',
      nutritionFacts: {
        '칼로리': '52 kcal',
        '식이섬유': '2.4 g',
        '비타민 C': '4.6 mg',
      },
      tip: '사과는 식이섬유가 풍부해 포만감을 오래 유지시켜 줍니다. 아침 공복에 먹으면 소화를 돕고 혈당 상승을 완만하게 합니다.',
    ),
    FoodSuggestion(
      emoji: '🍌',
      name: '바나나',
      nutritionFacts: {
        '칼로리': '89 kcal',
        '칼륨': '358 mg',
        '마그네슘': '27 mg',
      },
      tip: '운동 전후 간편한 에너지 보충 식품입니다. 칼륨이 풍부해 근육 경련 예방에도 도움을 줍니다.',
    ),
    FoodSuggestion(
      emoji: '🍊',
      name: '오렌지',
      nutritionFacts: {
        '칼로리': '47 kcal',
        '비타민 C': '53 mg',
        '수분': '87%',
      },
      tip: '풍부한 비타민 C로 면역력을 높이고 피로를 해소해 줍니다. 물 대신 상큼하게 수분을 채워보세요.',
    ),
    FoodSuggestion(
      emoji: '🥝',
      name: '키위',
      nutritionFacts: {
        '칼로리': '61 kcal',
        '비타민 C': '92.7 mg',
        '식이섬유': '3 g',
      },
      tip: '소화를 돕는 효소가 들어 있어 기름진 식사 후에 먹기 좋습니다. 알레르기 완화에도 도움이 되는 것으로 알려져 있어요.',
    ),
    FoodSuggestion(
      emoji: '🫐',
      name: '블루베리',
      nutritionFacts: {
        '칼로리': '57 kcal',
        '폴리페놀': '풍부',
        '비타민 K': '19.3 µg',
      },
      tip: '항산화 물질이 풍부해 눈 건강과 노화 방지에 도움이 됩니다. 요거트나 샐러드에 더해보세요.',
    ),
  ];

  static const List<FoodSuggestion> _vegetableSuggestions = [
    FoodSuggestion(
      emoji: '🥕',
      name: '당근',
      nutritionFacts: {
        '칼로리': '41 kcal',
        '베타카로틴': '8285 µg',
        '식이섬유': '2.8 g',
      },
      tip: '베타카로틴이 풍부해 눈 건강과 면역력 향상에 도움을 줍니다. 간단히 스틱으로 잘라 간식처럼 즐겨보세요.',
    ),
    FoodSuggestion(
      emoji: '🥒',
      name: '오이',
      nutritionFacts: {
        '칼로리': '16 kcal',
        '수분': '95%',
        '비타민 K': '16.4 µg',
      },
      tip: '수분 함량이 높아 갈증 해소와 피부 보습에 좋아요. 가볍게 소금에 절여 샐러드에 더해보세요.',
    ),
    FoodSuggestion(
      emoji: '🥬',
      name: '시금치',
      nutritionFacts: {
        '칼로리': '23 kcal',
        '철분': '2.7 mg',
        '엽산': '194 µg',
      },
      tip: '철분과 엽산이 풍부해 빈혈 예방에 도움을 줍니다. 살짝 데쳐 나물로 먹거나 스무디에 넣어 보세요.',
    ),
    FoodSuggestion(
      emoji: '🥦',
      name: '브로콜리',
      nutritionFacts: {
        '칼로리': '34 kcal',
        '비타민 C': '89.2 mg',
        '식이섬유': '2.6 g',
      },
      tip: '비타민 C와 식이섬유가 풍부해 면역력을 높이고 포만감을 유지해 줍니다. 살짝 찌거나 볶아 건강한 반찬으로 즐기세요.',
    ),
    FoodSuggestion(
      emoji: '🧅',
      name: '양파',
      nutritionFacts: {
        '칼로리': '40 kcal',
        '퀘르세틴': '풍부',
        '무기질': '칼륨 146 mg',
      },
      tip: '퀘르세틴이 풍부해 항산화와 혈액순환에 도움을 줍니다. 생으로 샐러드에 넣거나 캐러멜라이징해 풍미를 더해보세요.',
    ),
  ];

  FoodSuggestion pickRandomFruit() {
    return _fruitSuggestions[_random.nextInt(_fruitSuggestions.length)];
  }

  FoodSuggestion pickRandomVegetable() {
    return _vegetableSuggestions[_random.nextInt(_vegetableSuggestions.length)];
  }
}
