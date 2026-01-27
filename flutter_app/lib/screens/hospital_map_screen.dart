import 'package:flutter/material.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final List<_FloorInfo> _floors = const [
    _FloorInfo(
      label: '3F',
      description: '수술실 · 회복실',
      assetPath: 'assets/floors/floor_3f.png',
    ),
    _FloorInfo(
      label: '2F',
      description: '내과 · 영상의학과',
      assetPath: 'assets/floors/floor_2f.png',
    ),
    _FloorInfo(
      label: '1F',
      description: '원무과 · 진료접수 · 검진센터',
      assetPath: 'assets/floors/floor_1f.png',
    ),
    _FloorInfo(
      label: 'B1',
      description: '주차장 · 약국 · 편의시설',
      assetPath: 'assets/floors/floor_b1.png',
    ),
  ];

  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFloor = _floors[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 지도'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedFloor.label} 안내',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(selectedFloor.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );

                            return InteractiveViewer(
                              minScale: 0.9,
                              maxScale: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: SizedBox(
                                  width: size.width,
                                  height: size.height,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      selectedFloor.assetPath,
                                      width: size.width,
                                      height: size.height,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _FloorSelector(
                      floors: _floors,
                      selectedIndex: _selectedIndex,
                      onSelected: (index) =>
                          setState(() => _selectedIndex = index),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorSelector extends StatelessWidget {
  const _FloorSelector({
    required this.floors,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_FloorInfo> floors;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < floors.length; i++) ...[
            _FloorButton(
              label: floors[i].label,
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
              isFirst: i == 0,
              isLast: i == floors.length - 1,
            ),
            if (i != floors.length - 1)
              Container(height: 1, color: Colors.black.withOpacity(0.06)),
          ],
        ],
      ),
    );
  }
}

class _FloorButton extends StatelessWidget {
  const _FloorButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(20) : Radius.zero,
            bottom: isLast ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 14,
            color: selected ? Colors.white : const Color(0xFF1E2432),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FloorInfo {
  const _FloorInfo({
    required this.label,
    required this.description,
    required this.assetPath,
  });

  final String label;
  final String description;
  final String assetPath;
}
