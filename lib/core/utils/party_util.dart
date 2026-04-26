import 'package:flutter/material.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';

class PartyUtil {
  // 정당별 로고 URL (가로 3:1 비율 PNG)
  static String getPartyLogoUrl(String party) {
    if (party.contains('더불어민주당')) {
      return 'assets/images/party/minjoo.png';
    } else if (party.contains('국민의힘')) {
      return 'assets/images/party/power.png';
    } else if (party.contains('정의당')) {
      return 'assets/images/party/justice.png';
    } else if (party.contains('진보당')) {
      return 'assets/images/party/progressive.png';
    } else if (party.contains('조국혁신당')) {
      return 'assets/images/party/rebuilding.png';
    } else if (party.contains('개혁신당')) {
      return 'assets/images/party/reform.png';
    } else if (party.contains('기본소득당')) {
      return 'assets/images/party/basicincome.png';
    }
    return ''; // 로고 없음
  }

  // 정당별 색상 도우미
  static Color getPartyColor(String party) {
    if (party.contains('더불어민주당')) return const Color(0xFF004EA2);
    if (party.contains('국민의힘')) return const Color(0xFFE61E2B);
    if (party.contains('정의당')) return const Color(0xFFFFCC00);
    if (party.contains('진보당')) return const Color(0xFFD6001C);
    if (party.contains('조국혁신당')) return const Color(0xFF00A0E2);
    if (party.contains('개혁신당')) return const Color(0xFFFF7F00);
    if (party.contains('기본소득당')) return const Color(0xFF00D2C3);
    return AppColors.grey;
  }
}
