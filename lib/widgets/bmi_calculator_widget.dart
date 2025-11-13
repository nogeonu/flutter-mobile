import 'package:flutter/material.dart';

class BmiCalculatorWidget extends StatefulWidget {
  const BmiCalculatorWidget({super.key});

  @override
  State<BmiCalculatorWidget> createState() => _BmiCalculatorWidgetState();
}

class _BmiCalculatorWidgetState extends State<BmiCalculatorWidget> {
  double? _heightCm;
  double? _weightKg;
  double? _bmi;
  _BmiCategory? _category;

  Future<void> _openBmiInputSheet() async {
    final result = await showModalBottomSheet<_BmiInputResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _BmiInputSheet(
          initialHeightCm: _heightCm,
          initialWeightKg: _weightKg,
        );
      },
    );

    if (result != null) {
      _updateBmi(result.heightCm, result.weightKg);
    }
  }

  void _updateBmi(double heightCm, double weightKg) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    final category = _categorizeBmi(bmi);

    setState(() {
      _heightCm = heightCm;
      _weightKg = weightKg;
      _bmi = bmi;
      _category = category;
    });
  }

  _BmiCategory _categorizeBmi(double bmi) {
    if (bmi < 18.5) {
      return _BmiCategory.underweight;
    } else if (bmi < 24.9) {
      return _BmiCategory.normal;
    } else if (bmi < 29.9) {
      return _BmiCategory.overweight;
    } else {
      return _BmiCategory.obese;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final gradientColors = _category == null
        ? [
            colorScheme.primaryContainer.withOpacity(0.65),
            colorScheme.primaryContainer.withOpacity(0.35),
          ]
        : _category!.gradientColors(colorScheme);
    final accentColor = _category?.accentColor(colorScheme) ?? colorScheme.primary;
    final onContainerColor =
        _category?.onContainerColor(colorScheme) ?? colorScheme.onPrimaryContainer;

    final statusLabel = _category?.label ?? '오늘의 컨디션을 확인해보세요';
    final comment = _category?.comment ?? '카드를 터치하면 상큼한 몸 상태 리포트를 전해드릴게요.';
    final bmiText = _bmi != null ? 'BMI ${_bmi!.toStringAsFixed(1)}' : '기록 대기 중';

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: _openBmiInputSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 20,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '몸 컨디션 가이드',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _openBmiInputSheet,
                  icon: Icon(Icons.monitor_weight_outlined, color: accentColor),
                  tooltip: '몸 상태 다시 기록',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              bmiText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: onContainerColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onContainerColor.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            if (_heightCm != null && _weightKg != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _BmiInfoChip(
                    label: '키',
                    value: '${_heightCm!.toStringAsFixed(1)} cm',
                    accentColor: accentColor,
                  ),
                  _BmiInfoChip(
                    label: '체중',
                    value: '${_weightKg!.toStringAsFixed(1)} kg',
                    accentColor: accentColor,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BmiInputSheet extends StatefulWidget {
  const _BmiInputSheet({
    required this.initialHeightCm,
    required this.initialWeightKg,
  });

  final double? initialHeightCm;
  final double? initialWeightKg;

  @override
  State<_BmiInputSheet> createState() => _BmiInputSheetState();
}

class _BmiInputSheetState extends State<_BmiInputSheet> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.initialHeightCm != null ? widget.initialHeightCm!.toStringAsFixed(1) : '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeightKg != null ? widget.initialWeightKg!.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '값을 입력해주세요.';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return '숫자 형식으로 입력해주세요.';
    }
    if (number <= 0) {
      return '0보다 큰 값을 입력해주세요.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + mediaQuery.viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('몸 상태 기록하기', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '키와 체중을 가볍게 남기면 오늘의 컨디션 코멘트를 전해드려요.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '키 (cm)',
                hintText: '예: 170',
                border: OutlineInputBorder(),
              ),
              validator: _validatePositiveNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '체중 (kg)',
                hintText: '예: 65.5',
                border: OutlineInputBorder(),
              ),
              validator: _validatePositiveNumber,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final height = double.parse(_heightController.text.trim());
                  final weight = double.parse(_weightController.text.trim());
                  Navigator.of(context).pop(
                    _BmiInputResult(heightCm: height, weightKg: weight),
                  );
                }
              },
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiInfoChip extends StatelessWidget {
  const _BmiInfoChip({
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
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
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BmiInputResult {
  const _BmiInputResult({required this.heightCm, required this.weightKg});

  final double heightCm;
  final double weightKg;
}

enum _BmiCategory { underweight, normal, overweight, obese }

extension on _BmiCategory {
  String get label {
    switch (this) {
      case _BmiCategory.underweight:
        return '저체중 단계';
      case _BmiCategory.normal:
        return '정상 체중';
      case _BmiCategory.overweight:
        return '과체중 경고';
      case _BmiCategory.obese:
        return '비만 위험';
    }
  }

  String get comment {
    switch (this) {
      case _BmiCategory.underweight:
        return '영양 섭취를 늘리고 규칙적인 식사로 체중을 보충해보세요.';
      case _BmiCategory.normal:
        return '지금의 생활 습관을 유지하면서 균형 잡힌 식단과 운동을 이어가세요!';
      case _BmiCategory.overweight:
        return '가벼운 유산소와 근력 운동, 식습관 점검으로 체중을 관리해보세요.';
      case _BmiCategory.obese:
        return '전문의 상담과 함께 식단·운동 관리를 시작하면 건강을 지키는 데 도움이 돼요.';
    }
  }

  List<Color> gradientColors(ColorScheme colorScheme) {
    switch (this) {
      case _BmiCategory.underweight:
        return [
          colorScheme.secondaryContainer.withOpacity(0.7),
          colorScheme.secondaryContainer.withOpacity(0.4),
        ];
      case _BmiCategory.normal:
        return [
          colorScheme.primaryContainer.withOpacity(0.7),
          colorScheme.primaryContainer.withOpacity(0.4),
        ];
      case _BmiCategory.overweight:
        return [
          colorScheme.tertiaryContainer.withOpacity(0.7),
          colorScheme.tertiaryContainer.withOpacity(0.4),
        ];
      case _BmiCategory.obese:
        return [
          colorScheme.errorContainer.withOpacity(0.75),
          colorScheme.errorContainer.withOpacity(0.45),
        ];
    }
  }

  Color accentColor(ColorScheme colorScheme) {
    switch (this) {
      case _BmiCategory.underweight:
        return colorScheme.secondary;
      case _BmiCategory.normal:
        return colorScheme.primary;
      case _BmiCategory.overweight:
        return colorScheme.tertiary;
      case _BmiCategory.obese:
        return colorScheme.error;
    }
  }

  Color onContainerColor(ColorScheme colorScheme) {
    switch (this) {
      case _BmiCategory.underweight:
        return colorScheme.onSecondaryContainer;
      case _BmiCategory.normal:
        return colorScheme.onPrimaryContainer;
      case _BmiCategory.overweight:
        return colorScheme.onTertiaryContainer;
      case _BmiCategory.obese:
        return colorScheme.onErrorContainer;
    }
  }
}
