import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta e tema do app.
///
/// Visual "neon dark": fundo quase preto azulado, superfícies de vidro e
/// acentos em ciano -> roxo. Tudo o que é cor no app sai daqui — nenhuma tela
/// deve declarar `Color(0x...)` por conta própria.
class AppColors {
  AppColors._();

  // Fundo
  static const Color bgDeep = Color(0xFF04050D);
  static const Color bg = Color(0xFF080A18);
  static const Color bgElevated = Color(0xFF0E1226);

  // Acentos
  static const Color cyan = Color(0xFF29B6FF);
  static const Color blue = Color(0xFF3D7BFF);
  static const Color indigo = Color(0xFF6A4DFF);
  static const Color purple = Color(0xFF9B4DFF);
  static const Color magenta = Color(0xFFC94DFF);

  // Texto
  static const Color text = Color(0xFFE9F0FF);
  static const Color textDim = Color(0xFF9AA7C7);
  static const Color textFaint = Color(0xFF5E6C8C);

  // Semânticas
  static const Color success = Color(0xFF2FE08A);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFFB443);

  /// Borda padrão das superfícies de vidro.
  static Color get stroke => Colors.white.withValues(alpha: 0.10);
  static Color get strokeStrong => cyan.withValues(alpha: 0.35);

  /// Gradiente da marca: ciano (esquerda) -> roxo (direita).
  static const LinearGradient brand = LinearGradient(
    colors: [cyan, blue, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient brandSoft = LinearGradient(
    colors: [Color(0x3329B6FF), Color(0x339B4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Vidro das superfícies (cards, campos, sheets).
  static LinearGradient get glass => LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Halo colorido usado para dar a sensação de emissão de luz.
  static List<BoxShadow> glow(Color color, {double opacity = 0.45, double blur = 24, double spread = 0}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];
}

class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  /// Barra de status transparente com ícones claros — o fundo escuro vai até o topo.
  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        onPrimary: Colors.white,
        secondary: AppColors.purple,
        onSecondary: Colors.white,
        surface: AppColors.bgElevated,
        onSurface: AppColors.text,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlay,
        iconTheme: IconThemeData(color: AppColors.text, size: 26),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textDim),
      dividerColor: Colors.white12,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cyan,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: AppColors.stroke),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.bgElevated,
        hourMinuteTextColor: AppColors.text,
        dialHandColor: AppColors.cyan,
        dialBackgroundColor: Colors.white.withValues(alpha: 0.05),
        entryModeIconColor: AppColors.cyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.stroke),
        ),
      ),
    );
  }
}
