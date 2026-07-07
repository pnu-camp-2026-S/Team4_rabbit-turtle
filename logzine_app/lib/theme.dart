import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// claude.ai/design "탐색 홈 v2" 시안에서 추출한 에디토리얼 팔레트.
class AppColors {
  static const Color ink = Color(0xFF1C1C1E); // 본문/버튼 잉크 블랙
  static const Color inkHover = Color(0xFF4A5568); // 버튼 hover, 본문 슬레이트
  static const Color canvas = Color(0xFFE7E4DD); // 바깥 웜 그레이지
  static const Color screen = Color(0xFFF7F5F0); // 화면 배경 크림
  static const Color card = Color(0xFFFFFFFF); // 카드/입력창
  static const Color border = Color(0xFFE5E5E0); // 선/테두리
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8A8A8E);
  static const Color textMuted = Color(0xFFB0B0B4);
  static const Color body = Color(0xFF4A5568);
  static const Color placeholder = Color(0xFFEDEBE4); // 이미지 자리
  static const Color forest = Color(0xFF1C4A36); // 로그인 딥 그린 버튼
  static const Color forestDark = Color(0xFF153A2A); // 딥 그린 pressed
  static const Color wine = Color(0xFF8E3B46); // 로고 밑줄 와인 레드
  static const Color sage = Color(0xFF5B7A63); // muted sage-green (선택 태그 테두리/텍스트)
  static const Color sageSoft = Color(0xFFFBFAF7); // 태그 off-white 배경

  // 기존 회원가입 페이지 호환용 별칭
  static const Color primary = ink;
  static const Color primaryDark = inkHover;
  static const Color background = screen;
  static const Color surface = card;
}

/// 로고/영문 표제용 세리프 (Cormorant Garamond).
TextStyle logoStyle({
  double size = 26,
  FontWeight weight = FontWeight.w600,
  double letterSpacingEm = 0.14,
  Color color = AppColors.textPrimary,
}) {
  return GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: size * letterSpacingEm,
    color: color,
  );
}

/// 한글 제목용 세리프 (Noto Serif KR).
TextStyle serifHeading({
  double size = 19,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = -0.3,
  Color color = AppColors.textPrimary,
}) {
  return GoogleFonts.notoSerifKr(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
  );
}

/// Logzine 앱의 라이트 테마.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      primary: AppColors.ink,
    ).copyWith(surface: AppColors.screen),
    scaffoldBackgroundColor: AppColors.screen,
  );

  return base.copyWith(
    // 잡지 넘기듯 부드러운 슬라이드+페이드 전환 (기본 Zoom 전환 대체)
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoSerifKr(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
    ),
  );
}
