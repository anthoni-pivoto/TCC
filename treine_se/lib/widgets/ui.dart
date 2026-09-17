import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fundo padrão de todas as telas: preto azulado com dois halos de luz
/// (ciano em cima à esquerda, roxo embaixo à direita) e uma malha de pontos
/// bem discreta, que é o que dá a textura "tech" sem pesar na renderização.
class NeonBackground extends StatelessWidget {
  const NeonBackground({super.key, required this.child, this.showGrid = true});

  final Widget child;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bgDeep, AppColors.bg, Color(0xFF0B0A1C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -0.95),
                radius: 1.1,
                colors: [
                  AppColors.cyan.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, 0.9),
                radius: 1.1,
                colors: [
                  AppColors.purple.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
        child,
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  static const double _step = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (double y = 0; y < size.height; y += _step) {
      for (double x = 0; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Superfície de vidro: usada em cards, campos e caixas de destaque.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = AppRadius.lg,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.stroke;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.28),
              blurRadius: 26,
              spreadRadius: -4,
            ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.cyan.withValues(alpha: 0.10),
        highlightColor: AppColors.purple.withValues(alpha: 0.06),
        child: card,
      ),
    );
  }
}

/// Texto pintado com o gradiente da marca. Usado só em títulos grandes —
/// em corpo de texto o gradiente atrapalha a leitura.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppColors.brand,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Botão principal: pílula com gradiente e halo. Desabilitado ele perde o
/// brilho e o gradiente, para a diferença ficar óbvia no escuro.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.height = 56,
    this.fontSize = 18,
    this.gradient = AppColors.brand,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  final double height;
  final double fontSize;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.40),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.30),
                    blurRadius: 30,
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Center(
              child: loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        if (loadingLabel != null) ...[
                          const SizedBox(width: 14),
                          Flexible(
                            child: Text(
                              loadingLabel!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize - 3,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: fontSize + 4),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão secundário: só contorno luminoso, sem preenchimento.
class OutlineGlowButton extends StatelessWidget {
  const OutlineGlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.cyan,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Decoração de campo de texto no estilo do app: fundo de vidro, borda fina
/// que acende em ciano no foco.
InputDecoration neonInput({
  required String label,
  IconData? icon,
  Widget? suffix,
  String? hint,
}) {
  OutlineInputBorder borda(Color cor, double largura) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: cor, width: largura),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textFaint),
    labelStyle: const TextStyle(
      color: AppColors.textDim,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.cyan,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.045),
    prefixIcon:
        icon == null ? null : Icon(icon, color: AppColors.cyan, size: 21),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: borda(Colors.white.withValues(alpha: 0.12), 1.3),
    focusedBorder: borda(AppColors.cyan, 1.8),
    errorBorder: borda(AppColors.danger.withValues(alpha: 0.7), 1.3),
    focusedErrorBorder: borda(AppColors.danger, 1.8),
  );
}

/// Chip de seleção (dias, durações, lesões). Selecionado ganha gradiente e halo.
class NeonChip extends StatelessWidget {
  const NeonChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontSize = 12,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brand : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
            width: 1.3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDim,
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho de tela: título grande em gradiente, linha de contexto opcional e
/// um filete luminoso embaixo no lugar da régua sólida antiga.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 0),
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDim,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    GradientText(
                      title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          const GlowDivider(),
        ],
      ),
    );
  }
}

/// Filete horizontal que desbota nas pontas — substitui as barras sólidas.
class GlowDivider extends StatelessWidget {
  const GlowDivider({super.key, this.height = 1.5});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.0),
            AppColors.cyan.withValues(alpha: 0.7),
            AppColors.purple.withValues(alpha: 0.7),
            AppColors.purple.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.25, 0.75, 1],
        ),
      ),
    );
  }
}

/// Casca dos bottom sheets: fundo elevado, topo arredondado, alça em gradiente
/// e espaço reservado para o teclado.
class SheetShell extends StatelessWidget {
  const SheetShell({super.key, required this.child, this.scrollable = false});

  final Widget child;

  /// Sheets com formulário longo precisam rolar; os curtos não.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final conteudo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: AppColors.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        child,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.all(color: AppColors.stroke, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          14,
          24,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: scrollable ? SingleChildScrollView(child: conteudo) : conteudo,
      ),
    );
  }
}

/// Rótulo em caixa alta acima de um campo ou grupo de opções.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textDim,
          fontSize: 11.5,
          letterSpacing: 1.2,
        ),
      );
}

/// Selo circular com ícone e halo — usado nos diálogos.
class GlowBadge extends StatelessWidget {
  const GlowBadge({
    super.key,
    required this.icon,
    this.size = 76,
    this.gradient = AppColors.brand,
    this.glowColor = AppColors.blue,
  });

  final IconData icon;
  final double size;
  final Gradient gradient;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.55),
            blurRadius: 30,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}

/// Anel giratório com o ícone do app no centro, na tela de login.
class OrbitLogo extends StatefulWidget {
  const OrbitLogo({super.key, this.size = 190});

  final double size;

  @override
  State<OrbitLogo> createState() => _OrbitLogoState();
}

class _OrbitLogoState extends State<OrbitLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 0.85,
                height: widget.size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: _ctrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _RingPainter(tilt: 0.45, color: AppColors.cyan),
                ),
              ),
              Transform.rotate(
                angle: -_ctrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(widget.size * 0.88),
                  painter: _RingPainter(tilt: -0.6, color: AppColors.purple),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: widget.size * 0.44,
          height: widget.size * 0.44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brand,
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.6),
                blurRadius: 34,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: widget.size * 0.22,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.tilt, required this.color});

  final double tilt;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height * (0.45 + tilt.abs() * 0.25),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.9),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.5, 0.85],
      ).createShader(rect);

    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.tilt != tilt || oldDelegate.color != color;
}
