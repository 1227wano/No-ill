// 모든 위젯에 대한 일관된 스타일 부여
// global styling을 작성하는 곳

import 'package:flutter/material.dart';
import '../constants/color_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 1. 앱 전체 폰트 및 Material 3 적용
      useMaterial3: true,
      fontFamily: 'Pretendard', // 주석 부분을 실제 파라미터로 추가
      // 2. 메인 서비스용 전체 배경색 (밀키 아이보리)
      scaffoldBackgroundColor: NoIllColors.background,

      // 3. App Bar 공통 스타일
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: NoIllColors.textMain),
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          color: NoIllColors.textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // 4. 전체 색상 테마 설정
      colorScheme: ColorScheme.fromSeed(
        seedColor: NoIllColors.primary,
        primary: NoIllColors.primary,
        error: NoIllColors.danger,
        surface: NoIllColors.surface,
      ),

      // 5. 텍스트 테마 설정
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: NoIllColors.textMain,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: NoIllColors.textMain,
        ),
        labelSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: NoIllColors.textBody,
        ),
      ),

      // 6. 카드 공통 스타일 (에러 해결 핵심 지점)
      // shadowColor에 withOpacity가 있으므로 CardThemeData 앞에는 const를 붙이지 않습니다.
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // 7. 공통 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NoIllColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),

      // 8. 입력 필드 테마
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
        ),
      ),
    );
  }
}
