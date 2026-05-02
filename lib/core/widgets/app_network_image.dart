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

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      cacheWidth: memCacheWidth,
      cacheHeight: memCacheHeight,
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
        return errorWidget?.call(context, imageUrl, error) ??
            _buildErrorWidget(context, imageUrl, error);
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
