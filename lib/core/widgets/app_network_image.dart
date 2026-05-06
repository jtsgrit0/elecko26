import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context, imageUrl, 'Empty URL');
    }

    // 안정성을 위해 Image.network 대신 CachedNetworkImage와 유사한 패턴을 사용합니다.
    // 여기서는 errorBuilder를 강화하여 앱 크래시를 방지합니다.
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder?.call(context, imageUrl) ??
            Container(
              width: width,
              height: height,
              color: AppColors.lightGrey,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        // 웹 환경에서 404 에러 발생 시 앱이 멈추는 것을 방지하기 위해
        // 항상 에러 위젯을 반환하도록 합니다.
        print('### AppNetworkImage: 이미지 로드 실패 ###');
        print('URL: $imageUrl');
        print('Error: $error');
        return _buildErrorWidget(context, imageUrl, error);
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String url, dynamic error) {
    return Container(
      width: width,
      height: height,
      color: AppColors.lightGrey,
      child: const Icon(Icons.error_outline, color: AppColors.mediumGray),
    );
  }
}
