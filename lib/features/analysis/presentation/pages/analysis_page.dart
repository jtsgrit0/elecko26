import 'package:flutter/material.dart';
import 'package:elecko26/core/theme/app_theme.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String _sortBy = 'possibility'; // possibility, name, party
  String _filterParty = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 대시보드'),
      ),
      body: Column(
        children: [
          // 필터 및 정렬 섹션
          _buildFilterSection(),
          // 분석 결과 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _AnalysisResultCard(index: index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 필터 및 정렬 섹션
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필터 및 정렬',
            style: AppTextStyles.headline4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: '정렬',
                  value: _sortBy,
                  items: {
                    'possibility': '당선율 순',
                    'name': '이름 순',
                    'party': '정당 순',
                  },
                  onChanged: (value) {
                    setState(() => _sortBy = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  label: '정당',
                  value: _filterParty,
                  items: {
                    'all': '전체',
                    'democratic': '더불어민주당',
                    'power': '국민의힘',
                    'other': '기타정당',
                  },
                  onChanged: (value) {
                    setState(() => _filterParty = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 분석 결과 카드
class _AnalysisResultCard extends StatelessWidget {
  final int index;

  const _AnalysisResultCard({required this.index});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터
    final possibility = (index * 15.5 + 45).clamp(0.0, 100.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 의원 상세 페이지로 이동
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 의원 정보
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '의원 이름 $index',
                          style: AppTextStyles.headline4,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '정당',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '지역구',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 당선 가능성
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '당선 가능성',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        '${possibility.toStringAsFixed(1)}%',
                        style: AppTextStyles.headline4.copyWith(
                          color: possibility > 70
                              ? AppColors.success
                              : possibility > 50
                                  ? AppColors.secondary
                                  : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: possibility / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation(
                        possibility > 70
                            ? AppColors.success
                            : possibility > 50
                                ? AppColors.secondary
                                : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 점수 섹션
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ScoreItem('경력', 65),
                    _ScoreItem('활동', 72),
                    _ScoreItem('정책', 58),
                    _ScoreItem('여론', 45),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 보완점
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 보완점',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 로컬 미디어 노출 강화 필요\n• SNS 활동성 개선 권장',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 점수 아이템
class _ScoreItem extends StatelessWidget {
  final String label;
  final double score;

  const _ScoreItem(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppColors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(
                    score > 70
                        ? AppColors.success
                        : score > 50
                            ? AppColors.secondary
                            : AppColors.error,
                  ),
                  strokeWidth: 3,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

// 필터 드롭다운
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final Function(String) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 6),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: Container(),
          items: items.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }
}
