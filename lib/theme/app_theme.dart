import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final text = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    const r14 = BorderRadius.all(Radius.circular(14));

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.accent,
      canvasColor: AppColors.bg,
      dividerColor: AppColors.line,
      splashColor: AppColors.accent.withValues(alpha: 0.12),
      highlightColor: AppColors.accent.withValues(alpha: 0.08),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.bg,
        secondary: AppColors.accent400,
        onSecondary: AppColors.bg,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
        outline: AppColors.lineStrong,
        outlineVariant: AppColors.line,
      ),
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.8),
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.6),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.3),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.text),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      // Primary action = accent outline, never a flood.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.pressed)) return AppColors.accent.withValues(alpha: 0.22);
            if (s.contains(WidgetState.hovered)) return AppColors.accent.withValues(alpha: 0.12);
            return AppColors.accent.withValues(alpha: 0.06);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? AppColors.textFaint : AppColors.accent300),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.disabled) ? AppColors.lineStrong : AppColors.accent)),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: r14)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
          textStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
          overlayColor: WidgetStatePropertyAll(AppColors.accent.withValues(alpha: 0.10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line),
          shape: const RoundedRectangleBorder(borderRadius: r14),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentDeep,
        foregroundColor: AppColors.accent200,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.accent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        hintStyle: const TextStyle(color: AppColors.textFaint),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.accent300),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(borderRadius: r14, borderSide: BorderSide(color: AppColors.line)),
        enabledBorder: const OutlineInputBorder(borderRadius: r14, borderSide: BorderSide(color: AppColors.line)),
        focusedBorder: const OutlineInputBorder(borderRadius: r14, borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: const OutlineInputBorder(borderRadius: r14, borderSide: BorderSide(color: AppColors.danger)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: r14, borderSide: BorderSide(color: AppColors.danger, width: 1.5)),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: r14, side: BorderSide(color: AppColors.neutral800)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.text,
        unselectedLabelColor: AppColors.textFaint,
        indicatorColor: AppColors.accent,
        dividerColor: AppColors.line,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentTint,
        side: BorderSide(color: AppColors.line),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        shape: StadiumBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.lineStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)), side: BorderSide(color: AppColors.lineStrong)),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: r14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: GoogleFonts.inter(color: AppColors.text, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: r14, side: BorderSide(color: AppColors.accent700)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.neutral800,
        circularTrackColor: Colors.transparent,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.accentTint,
        headerForegroundColor: AppColors.text,
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.textMuted, textColor: AppColors.text),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent100 : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent700 : AppColors.neutral800),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.lineStrong),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      }),
    );
  }
}
