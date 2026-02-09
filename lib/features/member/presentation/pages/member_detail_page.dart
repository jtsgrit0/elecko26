import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

class MemberDetailPage extends StatefulWidget {
  final String memberId;

  const MemberDetailPage({
    Key? key,
    required this.memberId,
  }) : super(key: key);

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  int _selectedTabIndex = 0;
  static const List<double> _mockTrendValues = [
    0.42,
    0.44,
    0.43,
    0.46,
    0.45,
    0.47,
    0.49,
    0.48,
    0.50,
    0.51,
    0.49,
    0.52,
    0.54,
    0.53,
    0.55,
    0.56,
    0.54,
    0.57,
    0.58,
    0.57,
    0.59,
    0.60,
    0.58,
    0.61,
    0.62,
    0.61,
    0.63,
    0.64,
    0.63,
    0.65,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('의원 상세 정보'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 의원 프로필 섹션
            _buildProfileSection(),
            const SizedBox(height: 24),
            // 당선 가능성 카드
            _buildElectionPossibilityCard(),
            const SizedBox(height: 24),
            // 당선가능성 추이
            _buildTrendChartSection(),
            const SizedBox(height: 24),
            // 상세 정보 탭
            _buildDetailTabSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 프로필 섹션
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          // 프로필 이미지
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withOpacity(0.3),
              border: Border.all(
                color: AppColors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          // 기본 정보
          Text(
            '의원 이름',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip('정당'),
              const SizedBox(width: 8),
              _InfoChip('지역구'),
              const SizedBox(width: 8),
              _InfoChip('1선'),
            ],
          ),
        ],
      ),
    );
  }

  // 당선 가능성 카드
  Widget _buildElectionPossibilityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 당선 가능성',
              style: AppTextStyles.headline4,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '당선율',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0.0%',
                      style: AppTextStyles.headline2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '어제 대비',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '↑ 0.0%',
                      style: AppTextStyles.headline4.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 진행바
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChartSection() {
    final hasTrends = _mockTrendValues.isNotEmpty;
    final latest = hasTrends ? _mockTrendValues.last : 0.0;
    final earliest = hasTrends ? _mockTrendValues.first : 0.0;
    final delta = latest - earliest;
    final deltaPercent = delta * 100;
    final deltaColor = delta >= 0 ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '당선가능성 추이',
                  style: AppTextStyles.headline4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '30초 간격',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasTrends)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(latest * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.headline2.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: deltaColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${delta >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(2)}%p',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: _buildStockChart(_mockTrendValues),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChart(List<double> values) {
    if (values.isEmpty) {
      return Center(
        child: Text(
          '데이터 없음',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: _StockChartPainter(
          values: values,
          lineColor: AppColors.primary,
          fillColor: AppColors.primary,
          gridColor: AppColors.lightGrey.withOpacity(0.6),
          markerColor: AppColors.secondary,
          upColor: AppColors.success,
          downColor: AppColors.danger,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // 상세 정보 탭
  Widget _buildDetailTabSection() {
    return Column(
      children: [
        // 탭 버튼
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _TabButton(
                label: '경력',
                isSelected: _selectedTabIndex == 0,
                onPressed: () {
                  setState(() => _selectedTabIndex = 0);
                },
              ),
              const SizedBox(width: 12),
              _TabButton(
                label: '정책',
                isSelected: _selectedTabIndex == 1,
                onPressed: () {
                  setState(() => _selectedTabIndex = 1);
                },
              ),
              const SizedBox(width: 12),
              _TabButton(
                label: '언론',
                isSelected: _selectedTabIndex == 2,
                onPressed: () {
                  setState(() => _selectedTabIndex = 2);
                },
              ),
              const SizedBox(width: 12),
              _TabButton(
                label: '분석',
                isSelected: _selectedTabIndex == 3,
                onPressed: () {
                  setState(() => _selectedTabIndex = 3);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 탭 콘텐츠
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 250,
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  // 탭 콘텐츠
  Widget _buildTabContent() {
    List<Widget> contents = [
      _EmptyStateWidget('경력 정보가 없습니다', Icons.work),
      _EmptyStateWidget('정책 정보가 없습니다', Icons.policy),
      _EmptyStateWidget('언론 정보가 없습니다', Icons.newspaper),
      _EmptyStateWidget('분석 정보가 없습니다', Icons.analytics),
    ];

    return contents[_selectedTabIndex];
  }
}

// 정보 칩
class _InfoChip extends StatelessWidget {
  final String text;

  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// 탭 버튼
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          children: [
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    )
                  : AppTextStyles.labelMedium.copyWith(
                      color: AppColors.grey,
                    ),
            ),
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              Container(height: 3),
          ],
        ),
      ),
    );
  }
}

// 빈 상태 위젯
class _EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyStateWidget(this.message, this.icon);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color markerColor;
  final Color upColor;
  final Color downColor;

  _StockChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.markerColor,
    required this.upColor,
    required this.downColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    const padding = EdgeInsets.fromLTRB(12, 12, 12, 12);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001 ? 0.1 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = chartRect.top + (chartRect.height / gridLines) * i;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
    }

    final points = <Offset>[];
    final total = values.length;
    for (var i = 0; i < total; i++) {
      final x = total == 1
          ? chartRect.left + chartRect.width / 2
          : chartRect.left + (i / (total - 1)) * chartRect.width;
      final normalized = (values[i] - minValue) / range;
      final y = chartRect.bottom - normalized * chartRect.height;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          fillColor.withOpacity(0.35),
          fillColor.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    if (values.length > 1) {
      final step = chartRect.width / (values.length - 1);
      final bodyWidth = math.max(4.0, math.min(12.0, step * 0.6));
      for (var i = 1; i < values.length; i++) {
        final open = values[i - 1];
        final close = values[i];
        final high = open > close ? open : close;
        final low = open < close ? open : close;
        final color = close >= open ? upColor : downColor;

        final x = points[i].dx;
        final yOpen = chartRect.bottom - ((open - minValue) / range) * chartRect.height;
        final yClose = chartRect.bottom - ((close - minValue) / range) * chartRect.height;
        final yHigh = chartRect.bottom - ((high - minValue) / range) * chartRect.height;
        final yLow = chartRect.bottom - ((low - minValue) / range) * chartRect.height;

        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

        final top = math.min(yOpen, yClose);
        final bottom = math.max(yOpen, yClose);
        final bodyHeight = math.max(2.0, bottom - top);
        final bodyRect = Rect.fromCenter(
          center: Offset(x, top + bodyHeight / 2),
          width: bodyWidth,
          height: bodyHeight,
        );
        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(2)),
          bodyPaint,
        );
      }
    }

    final last = points.last;
    final markerPaint = Paint()..color = markerColor;
    canvas.drawCircle(last, 4, markerPaint);
    canvas.drawCircle(last, 9, Paint()..color = markerColor.withOpacity(0.15));
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.upColor != upColor ||
        oldDelegate.downColor != downColor;
  }
}
