import 'package:flutter/material.dart';

class SnsLinkItem extends StatelessWidget {
  final String platform;
  final VoidCallback onTap;

  const SnsLinkItem({
    super.key,
    required this.platform,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Chip(
        label: Text(platform),
        avatar: _getPlatformIcon(platform),
      ),
    );
  }

  Widget? _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Icon(Icons.facebook, color: Colors.blue);
      case 'twitter':
        return const Icon(Icons.alternate_email,
            color: Colors.lightBlue); // Using a generic icon for Twitter
      case 'youtube':
        return const Icon(Icons.play_arrow, color: Colors.red);
      case 'blog':
        return const Icon(Icons.article, color: Colors.orange);
      default:
        return null;
    }
  }
}
