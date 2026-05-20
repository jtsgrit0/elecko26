import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UiUtils {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static double screenWidth = ScreenUtil().screenWidth;
  static double screenHeight = ScreenUtil().screenHeight;

  // Add other UI utility methods as needed
}
