import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class FoodSuggestion {
  final String emoji;
  final String name;
  final Map<String, String> nutritionFacts;
  final String tip;
  final String? iconUrl;

  const FoodSuggestion({
    required this.emoji,
    required this.name,
    required this.nutritionFacts,
    required this.tip,
    this.iconUrl,
  });
}

class HealthInfoService {
  HealthInfoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Random _random = Random();

  static const String _defaultProduceIconUrl =
      'https://img.icons8.com/color/96/fruit-bowl.png';
  static const String _iconifyBaseUrl = 'https://api.iconify.design/';
  static const String _openMojiPngBaseUrl = 'https://openmoji.org/data/color/72x72/';

  List<FoodSuggestion> _remoteFruitCache = [];
  List<FoodSuggestion> _remoteVegetableCache = [];
  DateTime? _lastFruitFetch;
  DateTime? _lastVegetableFetch;
  bool _isFetchingFruit = false;
  bool _isFetchingVegetable = false;
  String? _lastFruitName;
  String? _lastVegetableName;

  static const List<FoodSuggestion> _fruitSuggestions = [
    FoodSuggestion(
      emoji: '🍎',
      name: '사과',
      nutritionFacts: {'칼로리': '52 kcal', '식이섬유': '2.4 g', '비타민 C': '4.6 mg'},
      tip: '사과는 식이섬유가 풍부해 포만감을 오래 유지시켜 줍니다. 아침 공복에 먹으면 소화를 돕고 혈당 상승을 완만하게 합니다.',
      iconUrl: '${_iconifyBaseUrl}twemoji/apple.png?width=96',
    ),
    FoodSuggestion(
      emoji: '🍌',
      name: '바나나',
      nutritionFacts: {'칼로리': '89 kcal', '칼륨': '358 mg', '마그네슘': '27 mg'},
      tip: '운동 전후 간편한 에너지 보충 식품입니다. 칼륨이 풍부해 근육 경련 예방에도 도움을 줍니다.',
      iconUrl: '${_iconifyBaseUrl}twemoji/banana.png?width=96',
    ),
    FoodSuggestion(
      emoji: '🍊',
      name: '오렌지',
      nutritionFacts: {'칼로리': '47 kcal', '비타민 C': '53 mg', '수분': '87%'},
      tip: '풍부한 비타민 C로 면역력을 높이고 피로를 해소해 줍니다. 물 대신 상큼하게 수분을 채워보세요.',
      iconUrl: '${_openMojiPngBaseUrl}1F34A.png',
    ),
    FoodSuggestion(
      emoji: '🥝',
      name: '키위',
      nutritionFacts: {'칼로리': '61 kcal', '비타민 C': '92.7 mg', '식이섬유': '3 g'},
      tip: '소화를 돕는 효소가 들어 있어 기름진 식사 후에 먹기 좋습니다. 알레르기 완화에도 도움이 되는 것으로 알려져 있어요.',
      iconUrl: '${_openMojiPngBaseUrl}1F95D.png',
    ),
    FoodSuggestion(
      emoji: '🫐',
      name: '블루베리',
      nutritionFacts: {'칼로리': '57 kcal', '폴리페놀': '풍부', '비타민 K': '19.3 µg'},
      tip: '항산화 물질이 풍부해 눈 건강과 노화 방지에 도움이 됩니다. 요거트나 샐러드에 더해보세요.',
      iconUrl: '${_openMojiPngBaseUrl}1FAD0.png',
    ),
  ];

  static const List<FoodSuggestion> _vegetableSuggestions = [
    FoodSuggestion(
      emoji: '🥕',
      name: '당근',
      nutritionFacts: {'칼로리': '41 kcal', '베타카로틴': '8285 µg', '식이섬유': '2.8 g'},
      tip: '베타카로틴이 풍부해 눈 건강과 면역력 향상에 도움을 줍니다. 간단히 스틱으로 잘라 간식처럼 즐겨보세요.',
      iconUrl: '${_iconifyBaseUrl}twemoji/carrot.png?width=96',
    ),
    FoodSuggestion(
      emoji: '🥒',
      name: '오이',
      nutritionFacts: {'칼로리': '16 kcal', '수분': '95%', '비타민 K': '16.4 µg'},
      tip: '수분 함량이 높아 갈증 해소와 피부 보습에 좋아요. 가볍게 소금에 절여 샐러드에 더해보세요.',
      iconUrl: '${_openMojiPngBaseUrl}1F952.png',
    ),
    FoodSuggestion(
      emoji: '🥬',
      name: '시금치',
      nutritionFacts: {'칼로리': '23 kcal', '철분': '2.7 mg', '엽산': '194 µg'},
      tip: '철분과 엽산이 풍부해 빈혈 예방에 도움을 줍니다. 살짝 데쳐 나물로 먹거나 스무디에 넣어 보세요.',
      iconUrl: '${_openMojiPngBaseUrl}1F96C.png',
    ),
    FoodSuggestion(
      emoji: '🥦',
      name: '브로콜리',
      nutritionFacts: {'칼로리': '34 kcal', '비타민 C': '89.2 mg', '식이섬유': '2.6 g'},
      tip: '비타민 C와 식이섬유가 풍부해 면역력을 높이고 포만감을 유지해 줍니다. 살짝 찌거나 볶아 건강한 반찬으로 즐기세요.',
      iconUrl: '${_iconifyBaseUrl}twemoji/broccoli.png?width=96',
    ),
    FoodSuggestion(
      emoji: '🧅',
      name: '양파',
      nutritionFacts: {'칼로리': '40 kcal', '퀘르세틴': '풍부', '무기질': '칼륨 146 mg'},
      tip: '퀘르세틴이 풍부해 항산화와 혈액순환에 도움을 줍니다. 생으로 샐러드에 넣거나 캐러멜라이징해 풍미를 더해보세요.',
      iconUrl: '${_openMojiPngBaseUrl}1F9C5.png',
    ),
  ];

  FoodSuggestion pickRandomFruit() {
    final suggestion = _pickRandomSuggestion(
      _fruitSuggestions,
      excludeName: _lastFruitName,
    );
    _lastFruitName = suggestion.name;
    return suggestion;
  }

  FoodSuggestion pickRandomVegetable() {
    final suggestion = _pickRandomSuggestion(
      _vegetableSuggestions,
      excludeName: _lastVegetableName,
    );
    _lastVegetableName = suggestion.name;
    return suggestion;
  }

  Future<FoodSuggestion> fetchRandomFruit() async {
    await _ensureFruitCache();
    if (_remoteFruitCache.isNotEmpty) {
      final suggestion = _pickRandomSuggestion(
        _remoteFruitCache,
        excludeName: _lastFruitName,
        fallbackSource: _fruitSuggestions,
      );
      _lastFruitName = suggestion.name;
      return suggestion;
    }
    return pickRandomFruit();
  }

  Future<FoodSuggestion> fetchRandomVegetable() async {
    await _ensureVegetableCache();
    if (_remoteVegetableCache.isNotEmpty) {
      final suggestion = _pickRandomSuggestion(
        _remoteVegetableCache,
        excludeName: _lastVegetableName,
        fallbackSource: _vegetableSuggestions,
      );
      _lastVegetableName = suggestion.name;
      return suggestion;
    }
    return pickRandomVegetable();
  }

  FoodSuggestion _pickRandomSuggestion(
    List<FoodSuggestion> source, {
    String? excludeName,
    List<FoodSuggestion>? fallbackSource,
  }) {
    if (source.isEmpty) {
      throw StateError('No suggestions available');
    }

    final filtered = excludeName == null
        ? source
        : source.where((item) => item.name != excludeName).toList();
    var pool = filtered.isEmpty ? source : filtered;

    if (excludeName != null && pool.length == 1 && pool.first.name == excludeName) {
      final fallback = fallbackSource ?? _fruitSuggestions;
      final fallbackFiltered = fallback.where((item) => item.name != excludeName).toList();
      if (fallbackFiltered.isNotEmpty) {
        pool = fallbackFiltered;
      }
    }

    return pool[_random.nextInt(pool.length)];
  }

  Future<void> _ensureFruitCache() async {
    if (_isFetchingFruit) return;
    final shouldRefresh =
        _remoteFruitCache.isEmpty ||
        _lastFruitFetch == null ||
        DateTime.now().difference(_lastFruitFetch!) > const Duration(hours: 6);
    if (!shouldRefresh) return;

    _isFetchingFruit = true;
    try {
      final response = await _client.get(
        Uri.parse('https://www.fruityvice.com/api/fruit/all'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map(_mapFruityViceToSuggestion)
            .whereType<FoodSuggestion>()
            .toList();
        if (parsed.isNotEmpty) {
          _remoteFruitCache = parsed;
          _lastFruitFetch = DateTime.now();
        }
      }
    } catch (_) {
      // 네트워크 오류 시 조용히 무시하고 하드코딩 데이터 사용
    } finally {
      _isFetchingFruit = false;
    }
  }

  Future<void> _ensureVegetableCache() async {
    if (_isFetchingVegetable) return;
    final shouldRefresh =
        _remoteVegetableCache.isEmpty ||
        _lastVegetableFetch == null ||
        DateTime.now().difference(_lastVegetableFetch!) >
            const Duration(hours: 6);
    if (!shouldRefresh) return;

    _isFetchingVegetable = true;
    try {
      final response = await _client.get(
        Uri.parse('https://www.freetestapi.com/api/v1/vegetables'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map(_mapVegetableApiToSuggestion)
            .whereType<FoodSuggestion>()
            .toList();
        if (parsed.isNotEmpty) {
          _remoteVegetableCache = parsed;
          _lastVegetableFetch = DateTime.now();
        }
      }
    } catch (_) {
      // 네트워크 오류 시 조용히 무시
    } finally {
      _isFetchingVegetable = false;
    }
  }

  FoodSuggestion? _mapFruityViceToSuggestion(Map<String, dynamic> item) {
    final rawName = item['name']?.toString();
    if (rawName == null || rawName.isEmpty) return null;
    final name = _localizeName(rawName);
    if (!_isLocalizedName(rawName, name)) {
      return null;
    }
    final emoji = _suggestEmojiForName(rawName, fallback: '🧺');
    final iconUrl = _resolveIconUrl(rawName) ?? _defaultProduceIconUrl;

    final nutritionFacts = <String, String>{};
    final nutritions = item['nutritions'];
    if (nutritions is Map<String, dynamic>) {
      final calories = nutritions['calories'];
      final sugar = nutritions['sugar'];
      final fiber = nutritions['fiber'] ?? nutritions['carbohydrates'];
      final potassium = nutritions['potassium'];
      if (calories != null) {
        nutritionFacts['칼로리'] = '${calories.toString()} kcal';
      }
      if (sugar != null) {
        nutritionFacts['당분'] = '${sugar.toString()} g';
      }
      if (fiber != null) {
        nutritionFacts['탄수화물'] = '${fiber.toString()} g';
      }
      if (potassium != null) {
        nutritionFacts['칼륨'] = '${potassium.toString()} mg';
      }
    }

    final family = item['family']?.toString();
    final order = item['order']?.toString();
    final tip = _buildFruitTip(
      name,
      family: family,
      order: order,
      nutritions: nutritions,
    );

    if (nutritionFacts.isEmpty) {
      nutritionFacts['영양 정보'] = '데이터 준비 중';
    }

    return FoodSuggestion(
      emoji: emoji,
      name: name,
      nutritionFacts: nutritionFacts,
      tip: tip,
      iconUrl: iconUrl,
    );
  }

  FoodSuggestion? _mapVegetableApiToSuggestion(Map<String, dynamic> item) {
    final rawName = (item['name'] ?? item['vegetable'] ?? item['title'])
        ?.toString();
    if (rawName == null || rawName.isEmpty) return null;
    final name = _localizeName(rawName);
    if (!_isLocalizedName(rawName, name)) {
      return null;
    }
    final emoji = _suggestEmojiForName(rawName, fallback: '🧺');
    final iconUrl = _defaultProduceIconUrl;

    final nutritionFacts = <String, String>{};
    final vitamins = item['vitamins'] ?? item['vitamin'];
    if (vitamins is List) {
      final vitaminList = vitamins.whereType<String>().take(3).toList();
      if (vitaminList.isNotEmpty) {
        nutritionFacts['비타민'] = vitaminList.join(', ');
      }
    } else if (vitamins is String && vitamins.isNotEmpty) {
      nutritionFacts['비타민'] = vitamins;
    }

    final calories = item['calories'];
    if (calories != null) {
      nutritionFacts['칼로리'] = '$calories kcal';
    }

    final minerals = item['minerals'];
    if (minerals is List && minerals.isNotEmpty) {
      nutritionFacts['미네랄'] = minerals.first.toString();
    } else if (minerals is String && minerals.isNotEmpty) {
      nutritionFacts['미네랄'] = minerals;
    }

    if (nutritionFacts.isEmpty) {
      nutritionFacts['영양 정보'] = '데이터 준비 중';
    }

    String tip = item['healthBenefits']?.toString() ?? '';
    if (tip.isEmpty) {
      tip = item['description']?.toString() ?? '';
    }
    if (tip.isEmpty) {
      tip = '$name은(는) 신선한 채소로 다양한 요리에 활용해보세요.';
    }

    return FoodSuggestion(
      emoji: emoji,
      name: name,
      nutritionFacts: nutritionFacts,
      tip: tip,
      iconUrl: iconUrl,
    );
  }

  static const Map<String, String> _koreanNameOverrides = {
    'apple': '사과',
    'pear': '배',
    'banana': '바나나',
    'orange': '오렌지',
    'kiwi': '키위',
    'blueberry': '블루베리',
    'blackberry': '블랙베리',
    'boysenberry': '보이즌베리',
    'cranberry': '크랜베리',
    'blackcurrant': '블랙커런트',
    'currant': '커런트',
    'gooseberry': '구스베리',
    'mulberry': '뽕나무열매',
    'elderberry': '엘더베리',
    'raspberry': '라즈베리',
    'strawberry': '딸기',
    'grape': '포도',
    'pineapple': '파인애플',
    'mango': '망고',
    'watermelon': '수박',
    'peach': '복숭아',
    'plum': '자두',
    'nectarine': '넥타린',
    'cherry': '체리',
    'grapefruit': '자몽',
    'pomelo': '자몽',
    'tangerine': '탠저린',
    'clementine': '클레멘타인',
    'mandarin': '만다린',
    'kumquat': '금귤',
    'apricot': '살구',
    'persimmon': '감',
    'papaya': '파파야',
    'passionfruit': '패션프루트',
    'pomegranate': '석류',
    'jackfruit': '잭프루트',
    'durian': '두리안',
    'lychee': '리치',
    'longan': '롱안',
    'rambutan': '람부탄',
    'starfruit': '스타프루트',
    'lime': '라임',
    'lemon': '레몬',
    'coconut': '코코넛',
    'avocado': '아보카도',
    'guava': '구아바',
    'mangosteen': '망고스틴',
    'dragonfruit': '용과',
    'melon': '멜론',
    'cantaloupe': '캔탈루프',
    'honeydew': '허니듀',
    'plantain': '플랜틴 바나나',
    'sapodilla': '사포딜라',
    'carrot': '당근',
    'cucumber': '오이',
    'zucchini': '주키니',
    'courgette': '코젯',
    'spinach': '시금치',
    'broccoli': '브로콜리',
    'cauliflower': '콜리플라워',
    'onion': '양파',
    'garlic': '마늘',
    'leek': '대파',
    'celery': '셀러리',
    'bokchoy': '청경채',
    'cabbage': '양배추',
    'brusselsprout': '방울양배추',
    'brusselsprouts': '방울양배추',
    'tomato': '토마토',
    'bellpepper': '피망',
    'pepper': '고추',
    'eggplant': '가지',
    'aubergine': '가지',
    'potato': '감자',
    'sweetpotato': '고구마',
    'yam': '얌',
    'pumpkin': '호박',
    'butternutsquash': '버터넛 호박',
    'squash': '스쿼시',
    'corn': '옥수수',
    'mushroom': '버섯',
    'okra': '오크라',
    'greenbean': '그린빈',
    'greenbeans': '그린빈',
    'stringbean': '스트링빈',
    'pea': '완두콩',
    'peas': '완두콩',
    'edamame': '에다마메',
    'radish': '무',
    'turnip': '순무',
    'beet': '비트',
    'beetroot': '비트',
    'parsnip': '파스닙',
    'ginger': '생강',
    'artichoke': '아티초크',
    'asparagus': '아스파라거스',
    'arugula': '루꼴라',
    'watercress': '물냉이',
  };

  static const Map<String, String> _iconifyIconOverrides = {
    'apple': 'twemoji/apple',
    'banana': 'twemoji/banana',
    'grape': 'twemoji/grapes',
    'pineapple': 'twemoji/pineapple',
    'strawberry': 'twemoji/strawberry',
    'watermelon': 'twemoji/watermelon',
    'carrot': 'twemoji/carrot',
    'broccoli': 'twemoji/broccoli',
    'tomato': 'twemoji/tomato',
    'pepper': 'twemoji/hot-pepper',
    'corn': 'twemoji/ear-of-corn',
    'potato': 'twemoji/potato',
  };

  static const Map<String, String> _openMojiCodepoints = {
    'orange': '1F34A',
    'tangerine': '1F34A',
    'clementine': '1F34A',
    'mandarin': '1F34A',
    'kiwi': '1F95D',
    'kiwifruit': '1F95D',
    'blueberry': '1FAD0',
    'blueberries': '1FAD0',
    'lemon': '1F34B',
    'lime': '1F34B',
    'pear': '1F350',
    'peach': '1F351',
    'mango': '1F96D',
    'papaya': '1F96D',
    'watermelon': '1F349',
    'melon': '1F348',
    'grapefruit': '1F34A',
    'guava': '1F96D',
    'dragonfruit': '1F965',
    'carrot': '1F955',
    'cucumber': '1F952',
    'zucchini': '1F952',
    'courgette': '1F952',
    'spinach': '1F96C',
    'leafygreen': '1F96C',
    'lettuce': '1F96C',
    'onion': '1F9C5',
    'garlic': '1F9C4',
    'eggplant': '1F346',
    'aubergine': '1F346',
    'mushroom': '1F344',
    'corn': '1F33D',
    'potato': '1F954',
    'sweetpotato': '1F360',
    'pumpkin': '1F383',
    'ginger': '1F9C2',
    'radish': '1FCE3',
  };

  String _suggestEmojiForName(String rawName, {required String fallback}) {
    final key = _normalizeKey(rawName);
    final firstKey = _firstWordKey(rawName);

    // 간단한 룰 기반 매핑: 과일/채소 유형별 기본 이모지 반환
    const fruitKeys = {
      'apple',
      'pear',
      'banana',
      'orange',
      'mandarin',
      'tangerine',
      'clementine',
      'grapefruit',
      'pomelo',
      'lime',
      'lemon',
      'mango',
      'papaya',
      'passionfruit',
      'dragonfruit',
      'guava',
      'avocado',
      'pineapple',
      'watermelon',
      'melon',
      'cantaloupe',
      'honeydew',
      'peach',
      'plum',
      'nectarine',
      'apricot',
      'cherry',
      'grape',
      'berry',
      'strawberry',
      'blueberry',
      'raspberry',
      'blackberry',
      'cranberry',
      'currant',
      'gooseberry',
      'mulberry',
      'elderberry',
      'jackfruit',
      'durian',
      'lychee',
      'longan',
      'rambutan',
      'starfruit',
      'sapodilla',
      'plantain',
      'pomegranate',
      'persimmon',
      'fig',
      'date',
      'kiwi',
    };

    const vegetableKeys = {
      'carrot',
      'cucumber',
      'zucchini',
      'courgette',
      'spinach',
      'broccoli',
      'cauliflower',
      'onion',
      'garlic',
      'leek',
      'celery',
      'bokchoy',
      'cabbage',
      'brusselsprout',
      'kale',
      'lettuce',
      'tomato',
      'bellpepper',
      'pepper',
      'eggplant',
      'aubergine',
      'potato',
      'sweetpotato',
      'yam',
      'pumpkin',
      'squash',
      'butternutsquash',
      'corn',
      'mushroom',
      'okra',
      'greenbean',
      'bean',
      'pea',
      'edamame',
      'radish',
      'turnip',
      'beet',
      'parsnip',
      'ginger',
      'artichoke',
      'asparagus',
      'arugula',
      'watercress',
    };

    if (fruitKeys.any(
      (candidate) => key.contains(candidate) || firstKey.contains(candidate),
    )) {
      return '🧺';
    }
    if (vegetableKeys.any(
      (candidate) => key.contains(candidate) || firstKey.contains(candidate),
    )) {
      return '🧺';
    }

    return fallback;
  }

  String? _resolveIconUrl(String rawName) {
    final key = _normalizeKey(rawName);
    final firstKey = _firstWordKey(rawName);

    final iconifyPath =
        _iconifyIconOverrides[key] ?? _iconifyIconOverrides[firstKey];
    if (iconifyPath != null) {
      return '$_iconifyBaseUrl$iconifyPath.png?width=96';
    }

    final codePoint = _openMojiCodepoints[key] ?? _openMojiCodepoints[firstKey];
    if (codePoint != null) {
      return '$_openMojiPngBaseUrl$codePoint.png';
    }

    return null;
  }

  bool _isLocalizedName(String rawName, String localizedName) {
    if (_containsHangul(localizedName)) {
      return true;
    }
    final rawNormalized = rawName.trim().toLowerCase();
    final localizedNormalized = localizedName.trim().toLowerCase();
    if (rawNormalized == localizedNormalized) {
      return false;
    }
    return _containsHangul(localizedName);
  }

  bool _containsHangul(String value) {
    return RegExp(r'[가-힣]').hasMatch(value);
  }

  String _normalizeKey(String rawName) {
    return rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _firstWordKey(String rawName) {
    final first = rawName.split(RegExp(r'\s|-|_')).first;
    return _normalizeKey(first);
  }

  String _localizeName(String rawName) {
    final key = _normalizeKey(rawName);
    final firstKey = _firstWordKey(rawName);
    if (_koreanNameOverrides.containsKey(key)) {
      return _koreanNameOverrides[key]!;
    }
    if (_koreanNameOverrides.containsKey(firstKey)) {
      return _koreanNameOverrides[firstKey]!;
    }
    return rawName;
  }

  String _buildFruitTip(
    String name, {
    String? family,
    String? order,
    Map<String, dynamic>? nutritions,
  }) {
    final highlight = _buildNutritionHighlight(nutritions);
    final familyPart = family != null && family.isNotEmpty
        ? '$family(과)'
        : null;
    final orderPart = order != null && order.isNotEmpty ? '$order(목)' : null;
    final parts = <String>[
      '$name은(는) 자연 당분과 수분이 균형 잡혀 있어 가벼운 간식으로 좋아요.',
      if (highlight != null) highlight,
      if (familyPart != null) '$familyPart 계열로 알려진 과일이에요.',
      if (orderPart != null) '$orderPart 식물군에 속해 균형 잡힌 영양을 제공합니다.',
    ];
    return parts.join(' ');
  }

  String? _buildNutritionHighlight(Map<String, dynamic>? nutritions) {
    if (nutritions == null || nutritions.isEmpty) {
      return null;
    }

    double? calories = _parseDouble(nutritions['calories']);
    double? sugar = _parseDouble(nutritions['sugar']);
    double? carbohydrates = _parseDouble(nutritions['carbohydrates']);
    double? protein = _parseDouble(nutritions['protein']);
    double? fat = _parseDouble(nutritions['fat']);

    if (calories != null && calories <= 60) {
      return '한 조각만으로도 ${calories.toStringAsFixed(0)} kcal 정도라 부담 없이 즐길 수 있어요.';
    }
    if (sugar != null && sugar >= 10) {
      return '자연 당분이 풍부해 운동 전후 빠르게 에너지를 채워 줍니다.';
    }
    if (carbohydrates != null && carbohydrates >= 12) {
      return '탄수화물이 충분해 든든한 간식이 되어 줍니다.';
    }
    if (protein != null && protein >= 1.5) {
      return '식물성 단백질이 들어 있어 균형 잡힌 영양 섭취에 도움이 됩니다.';
    }
    if (fat != null && fat <= 1) {
      return '지방 함량이 낮아 가볍게 즐겨도 부담이 덜해요.';
    }

    return '비타민과 미네랄이 고르게 들어 있어 활력을 더해 줍니다.';
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9\.-]'), '');
      return double.tryParse(normalized);
    }
    return null;
  }
}
