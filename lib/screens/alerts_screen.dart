import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/bmi_calculator_widget.dart';
import 'package:flutter_app/services/health_info_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final HealthInfoService _healthInfoService = HealthInfoService();
  static const String _fruitIntroText = '오늘의 과일 추천을 받아보세요! 신선한 에너지와 영양 정보를 한 번에 확인해요.';
  static const String _vegetableIntroText = '오늘의 채소 추천으로 가볍게 건강을 챙겨보세요. 간단 레시피와 영양 팁도 함께 전해드려요!';

  FoodSuggestion? _fruitSuggestion;
  FoodSuggestion? _vegetableSuggestion;
  bool _isFruitLoading = false;
  bool _isVegetableLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFruitSuggestion();
    _loadVegetableSuggestion();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFruitSuggestion() async {
    setState(() {
      _isFruitLoading = true;
    });

    try {
      final suggestion = await _healthInfoService.fetchRandomFruit();
      if (!mounted) return;
      setState(() {
        _fruitSuggestion = suggestion;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fruitSuggestion = _healthInfoService.pickRandomFruit();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFruitLoading = false;
        });
      }
    }
  }

  Future<void> _loadVegetableSuggestion() async {
    setState(() {
      _isVegetableLoading = true;
    });

    try {
      final suggestion = await _healthInfoService.fetchRandomVegetable();
      if (!mounted) return;
      setState(() {
        _vegetableSuggestion = suggestion;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vegetableSuggestion = _healthInfoService.pickRandomVegetable();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVegetableLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView( // 내용이 길어질 경우 스크롤 가능하도록 SingleChildScrollView 추가
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('건강 알림', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('맞춤 알림과 공지 사항을 받아보세요.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 32),

          // BMI 카드 섹션
          BmiCalculatorWidget(),
          const SizedBox(height: 40),

          // 랜덤 식재료 추천 섹션
          _FoodRecommendationCard(
            suggestion: _fruitSuggestion,
            placeholderText: _fruitIntroText,
            onPressed: _loadFruitSuggestion,
            isFruit: true,
            isLoading: _isFruitLoading,
          ),
          const SizedBox(height: 24),
          _FoodRecommendationCard(
            suggestion: _vegetableSuggestion,
            placeholderText: _vegetableIntroText,
            onPressed: _loadVegetableSuggestion,
            isFruit: false,
            isLoading: _isVegetableLoading,
          ),
        ],
      ),
    );
  }
}

class _SuggestionIcon extends StatelessWidget {
  const _SuggestionIcon({
    required this.emojiFallback,
    required this.iconUrl,
    required this.accentColor,
  });

  final String emojiFallback;
  final String? iconUrl;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null || iconUrl!.isEmpty) {
      return Text(
        emojiFallback,
        style: const TextStyle(fontSize: 42),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accentColor.withOpacity(0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        iconUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            emojiFallback,
            style: const TextStyle(fontSize: 36),
          ),
        ),
      ),
    );
  }
}

class _FoodRecommendationCard extends StatelessWidget {
  const _FoodRecommendationCard({
    required this.suggestion,
    required this.placeholderText,
    required this.onPressed,
    required this.isFruit,
    required this.isLoading,
  });

  final FoodSuggestion? suggestion;
  final String placeholderText;
  final VoidCallback onPressed;
  final bool isFruit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = isFruit
        ? [
            colorScheme.primaryContainer.withOpacity(0.65),
            colorScheme.primaryContainer.withOpacity(0.35),
          ]
        : [
            colorScheme.secondaryContainer.withOpacity(0.65),
            colorScheme.secondaryContainer.withOpacity(0.35),
          ];
    final accentColor = isFruit ? colorScheme.primary : colorScheme.secondary;
    final onContainerColor =
        isFruit ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer;
    final tooltipLabel = isFruit ? '다른 과일 추천 받기' : '다른 채소 추천 받기';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '오늘의 추천',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onPressed,
                icon: Icon(Icons.refresh_rounded, color: accentColor),
                tooltip: tooltipLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading) ...[
            const SizedBox(height: 4),
            Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '조금만 기다려 주세요. 신선한 추천을 불러오고 있어요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onContainerColor.withOpacity(0.8),
              ),
            ),
          ] else if (suggestion == null) ...[
            Text(
              placeholderText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onContainerColor.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로고침 아이콘을 눌러 다른 추천을 받아보세요.',
              style: theme.textTheme.labelMedium?.copyWith(
                color: onContainerColor.withOpacity(0.7),
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SuggestionIcon(
                  emojiFallback: suggestion!.emoji,
                  iconUrl: suggestion!.iconUrl,
                  accentColor: accentColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion!.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        suggestion!.tip,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: onContainerColor.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '주요 영양 성분 (100g 기준)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: suggestion!.nutritionFacts.entries.map((entry) {
                return _NutritionChip(
                  label: entry.key,
                  value: entry.value,
                  accentColor: accentColor,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
