import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';

class RegionSelectionPrompt extends StatelessWidget {
  final VoidCallback onSelectRegion;

  const RegionSelectionPrompt({
    Key? key,
    required this.onSelectRegion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '우리 동네 의원님들에게\n소중한 한 표를!',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '지역을 설정하시면 거주하시는 구역의\n후보자 리스트에 즉시 참여하실 수 있습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onSelectRegion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '지금 내 지역 설정하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
