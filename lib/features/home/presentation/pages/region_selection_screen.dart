import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';

class RegionSelectionScreen extends StatefulWidget {
  final ValueChanged<String> onRegionSelected;

  const RegionSelectionScreen({Key? key, required this.onRegionSelected})
      : super(key: key);

  @override
  State<RegionSelectionScreen> createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<RegionSelectionScreen> {
  static const List<String> _regions = [
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원도',
    '충청북도',
    '충청남도',
    '전북특별자치도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
    '전국',
  ];

  String? _selectedRegion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '환영합니다!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '관심 있는 지역을 먼저 선택해주세요.\n해당 지역의 데이터를 최우선으로 분석합니다.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Region Grid
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _regions.length,
                        itemBuilder: (context, index) {
                          final region = _regions[index];
                          final isSelected = _selectedRegion == region;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRegion = region;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.lightGrey,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                region.replaceAll('특별자치', '').replaceAll('광역시', ''),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.dark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Start Button
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: ElevatedButton(
                          onPressed: _selectedRegion == null
                              ? null
                              : () {
                                  widget.onRegionSelected(_selectedRegion!);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.lightGrey,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '당예기 시작하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
