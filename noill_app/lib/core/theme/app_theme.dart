// 모든 위젯에 대한 일관된 스타일 부여
// global styling을 작성하는 곳
import 'package:flutter/material.dart';
import '../constants/color_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NoIllColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NoIllColors.primary,
        primary: NoIllColors.primary,
        error: NoIllColors.danger,
        surface: NoIllColors.surface,
      ),
      // 폰트 스타일 설정 (Pretendard 권장)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700, // bold
          color: NoIllColors.textMain,
        ), // H1
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500, // medium
          color: NoIllColors.textMain,
        ), // B1
        labelSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400, // regular
          color: NoIllColors.textBody,
        ), // Caption
      ),
      // 공통 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NoIllColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52), // 모달/로그인 버튼 규격
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NoIllColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NoIllColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NoIllColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: NoIllColors.primary, width: 2),
        ), //
      ),
    );
  }
}
