import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';

class LocationSelectionModal extends StatelessWidget {
  final String? currentRegion;
  final ValueChanged<String> onRegionSelected;

  const LocationSelectionModal({
    Key? key,
    this.currentRegion,
    required this.onRegionSelected,
  }) : super(key: key);

  static const List<String> _regions = [
    '서울특별시', '부산광역시', '대구광역시', '인천광역시', 
    '광주광역시', '대전광역시', '울산광역시', '세종특별자치시',
    '경기도', '강원도', '충청북도', '충청남도', 
    '전북특별자치도', '전라남도', '경상북도', '경상남도', 
    '제주특별자치도', '전국'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '지역을 선택해주세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '선택하신 지역의 정보를 가장 먼저 보여드려요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _regions.length,
              itemBuilder: (context, index) {
                final region = _regions[index];
                final isSelected = region == currentRegion;
                return InkWell(
                  onTap: () => onRegionSelected(region),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.lightGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      region.replaceAll('특별자치', '').replaceAll('광역시', ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.darkGray,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
