import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class TreinoDetalheScreen extends StatefulWidget {
  final Map<String, dynamic> treino;
  final int idUsuario;

  const TreinoDetalheScreen({
    super.key,
    required this.treino,
    required this.idUsuario,
  });

  @override
  State<TreinoDetalheScreen> createState() => _TreinoDetalheScreenState();
}

class _TreinoDetalheScreenState extends State<TreinoDetalheScreen> {
  late Future<Map<String, Map<String, dynamic>>> _firestoreFuture;

  final Set<int> _concluidos  = {};
  final Set<int> _expandidos  = {};
  final Map<int, int>   _timerSegundos = {};
  final Map<int, Timer> _timers        = {};
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _firestoreFuture = _carregarDadosFirestore();
    NotificationService.cancelarInatividade();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarBoasVindas());
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _iniciarTimer(int index, int segundos, String nomeExercicio) {
    _timers[index]?.cancel();
    setState(() => _timerSegundos[index] = segundos);

    _timers[index] = Timer.periodic(const Duration(seconds: 1), (t) {
      final restante = (_timerSegundos[index] ?? 1) - 1;
      if (restante <= 0) {
        t.cancel();
        _timers.remove(index);
        if (mounted) {
          setState(() => _timerSegundos[index] = 0);
          NotificationService.notificarDescansoEncerrado(nomeExercicio);
        }
      } else {
        if (mounted) setState(() => _timerSegundos[index] = restante);
      }
    });
  }

  void _cancelarTimer(int index) {
    _timers[index]?.cancel();
    _timers.remove(index);
    setState(() => _timerSegundos.remove(index));
  }

  String _formatarTempo(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ── Boas-vindas ───────────────────────────────────────────────────────────

  Future<void> _mostrarBoasVindas() {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) =>
          _WelcomeDialog(dia: widget.treino['dia_treino'] as int),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Dados Firestore ───────────────────────────────────────────────────────

  Future<Map<String, Map<String, dynamic>>> _carregarDadosFirestore() async {
    final exercicios = widget.treino['exercicios'] as List;
    final slugs = exercicios
        .map((e) => e['slug_firebase'] as String)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final resultados = await Future.wait(
      slugs.map((slug) async {
        try {
          final resp = await http.get(Uri.parse('$baseUrl/api/exercicios/detalhe/$slug'));
          if (resp.statusCode == 200) {
            return MapEntry(slug, jsonDecode(resp.body) as Map<String, dynamic>);
          }
        } catch (_) {}
        return MapEntry(slug, <String, dynamic>{});
      }),
    );

    return Map.fromEntries(resultados);
  }

  // ── Registrar treino ──────────────────────────────────────────────────────

  Future<void> _registrarTreino() async {
    final List exercicios = widget.treino['exercicios'] ?? [];
    final int qtdConcluidos = _concluidos.length;
    final bool completo = qtdConcluidos == exercicios.length;

    setState(() => _registrando = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/frequencias/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': widget.idUsuario,
          'treino_completo': completo,
          'qtd_exercicios_concluidos': qtdConcluidos,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        await NotificationService.agendarInatividade();
        await _mostrarSucessoTreino(
            completo: completo, qtd: qtdConcluidos, total: exercicios.length);
        if (mounted) Navigator.pop(context);
      } else {
        _aviso('Erro ao registrar treino.');
      }
    } catch (e) {
      debugPrint('ERRO ao registrar treino: $e');
      if (mounted) _aviso('Erro: $e');
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Future<void> _mostrarSucessoTreino(
      {required bool completo, required int qtd, required int total}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => _WorkoutSuccessDialog(
          completo: completo, qtdConcluidos: qtd, totalExercicios: total),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final int dia = widget.treino['dia_treino'];
    final List exercicios = widget.treino['exercicios'] ?? [];

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho com progresso no lugar da AppBar sólida.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.text),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Voltar',
                    ),
                    Expanded(
                      child: GradientText(
                        'Dia $dia',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${_concluidos.length}/${exercicios.length}',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Barra de progresso do treino
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Stack(
                    children: [
                      Container(
                        height: 5,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        widthFactor: exercicios.isEmpty
                            ? 0
                            : _concluidos.length / exercicios.length,
                        child: Container(
                          height: 5,
                          decoration: const BoxDecoration(
                            gradient: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _firestoreFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.cyan));
                    }
                    final firestoreData = snapshot.data ?? {};
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final ex =
                                    exercicios[index] as Map<String, dynamic>;
                                final fsData =
                                    firestoreData[ex['slug_firebase']] ?? {};
                                return _buildExercicioCard(ex, fsData, index);
                              },
                              childCount: exercicios.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: _buildRegistrarButton(exercicios.length)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card de exercício ─────────────────────────────────────────────────────

  Widget _buildExercicioCard(Map<String, dynamic> ex, Map<String, dynamic> fs, int index) {
    final gifUrl = (ex['slug_firebase'] as String?)?.isNotEmpty == true
        ? '$baseUrl/api/exercicios/gif/${ex['slug_firebase']}'
        : null;
    final equipment   = fs['equipamento'] as String?;
    final dicas       = (fs['dicas_execucao'] as List?)?.cast<String>() ?? [];
    final secundarios = (fs['musculos_secundarios'] as List?)?.cast<String>() ?? [];
    final concluido   = _concluidos.contains(index);
    final expandido   = _expandidos.contains(index);
    final int tempoDescanso = (ex['tempo_descanso_s'] as num?)?.toInt() ?? 60;
    final String nome = ex['nm_exercicio'] as String? ?? '';
    final timerAtivo    = _timers.containsKey(index);
    final timerSegundos = _timerSegundos[index];

    final Color acento = concluido ? AppColors.success : AppColors.cyan;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      borderColor: concluido
          ? AppColors.success.withValues(alpha: 0.5)
          : AppColors.stroke,
      glowColor: concluido ? AppColors.success : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Header: toca para expandir ──────────────────────────────
            GestureDetector(
              onTap: () => setState(() {
                if (expandido) { _expandidos.remove(index); }
                else { _expandidos.add(index); }
              }),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Círculo numerado / check
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: concluido
                            ? const LinearGradient(
                                colors: [AppColors.success, AppColors.cyan])
                            : AppColors.brand,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: acento.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: concluido
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 19)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 13),

                    // Nome + resumo de séries
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: concluido
                                  ? AppColors.textDim
                                  : AppColors.text,
                              decoration:
                                  concluido ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.textFaint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ex['qtd_series']}x${ex['qtd_repeticoes']}  ·  ${ex['tempo_descanso_s']}s descanso',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textFaint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botão concluir
                    GestureDetector(
                      onTap: () => setState(() {
                        if (concluido) { _concluidos.remove(index); }
                        else { _concluidos.add(index); }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 4),
                        child: Icon(
                          concluido
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: concluido
                              ? AppColors.success
                              : AppColors.textFaint,
                          size: 26,
                        ),
                      ),
                    ),

                    // Seta expand
                    AnimatedRotation(
                      turns: expandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textFaint,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Corpo expansível ────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: expandido
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const GlowDivider(height: 1),

                        // GIF
                        if (gifUrl != null)
                          Container(
                            color: Colors.white,
                            child: Image.network(
                              Uri.encodeFull(gifUrl),
                              height: 200,
                              fit: BoxFit.contain,
                              headers: const {'Accept': 'image/gif,image/*'},
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                color: AppColors.cyan),
                                          ),
                                        ),
                              errorBuilder: (_, __, ___) => const SizedBox(
                                height: 80,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: AppColors.textFaint, size: 36),
                                ),
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat('Séries', '${ex['qtd_series']}',
                                      AppColors.cyan),
                                  _buildStat('Reps', '${ex['qtd_repeticoes']}',
                                      AppColors.blue),
                                  _buildStat(
                                      'Descanso',
                                      '${ex['tempo_descanso_s']}s',
                                      AppColors.purple),
                                ],
                              ),

                              if (equipment != null) ...[
                                const SizedBox(height: 14),
                                _buildInfoRow(
                                    Icons.fitness_center_rounded, equipment),
                              ],
                              if (secundarios.isNotEmpty) ...[
                                const SizedBox(height: 7),
                                _buildInfoRow(Icons.accessibility_new_rounded,
                                    secundarios.join(', ')),
                              ],
                              if (dicas.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const FieldLabel('Dicas de execução'),
                                const SizedBox(height: 8),
                                ...dicas.map((dica) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            top: 6, right: 9),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.cyan,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          dica,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.textDim,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],

                              // Timer de descanso
                              const SizedBox(height: 18),
                              _buildTimerSection(
                                index, tempoDescanso, nome, timerAtivo, timerSegundos),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timer de descanso ─────────────────────────────────────────────────────

  Widget _buildTimerSection(
      int index, int tempoDescanso, String nome, bool timerAtivo, int? timerSegundos) {
    final bool encerrado = timerSegundos == 0 && !timerAtivo;
    final int mostrar = timerSegundos ?? tempoDescanso;
    final double progresso =
        timerSegundos != null && tempoDescanso > 0 ? timerSegundos / tempoDescanso : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: timerAtivo
              ? AppColors.cyan.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.3,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 19,
                color: timerAtivo ? AppColors.cyan : AppColors.textFaint,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Descanso entre séries',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDim,
                  ),
                ),
              ),

              // Contador
              if (timerSegundos != null) ...[
                Text(
                  _formatarTempo(mostrar),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: timerAtivo
                        ? AppColors.cyan
                        : (encerrado ? AppColors.success : AppColors.text),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Botão iniciar / parar / repetir
              GestureDetector(
                onTap: () => timerAtivo
                    ? _cancelarTimer(index)
                    : _iniciarTimer(index, tempoDescanso, nome),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: timerAtivo ? null : AppColors.brand,
                    color: timerAtivo
                        ? Colors.white.withValues(alpha: 0.08)
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: timerAtivo
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.15))
                        : null,
                    boxShadow: timerAtivo
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: -3,
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        timerAtivo
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: timerAtivo ? AppColors.textDim : Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timerAtivo ? 'Parar' : (encerrado ? 'Repetir' : 'Iniciar'),
                        style: TextStyle(
                          color: timerAtivo ? AppColors.textDim : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Barra de progresso (só enquanto ativo)
          if (timerAtivo && timerSegundos != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresso,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Botão registrar ───────────────────────────────────────────────────────

  Widget _buildRegistrarButton(int totalExercicios) {
    final int qtd = _concluidos.length;
    final bool algumMarcado = qtd > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientText(
                '$qtd / $totalExercicios',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              const Text(
                'exercícios concluídos',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'REGISTRAR TREINO',
            onPressed: algumMarcado ? _registrarTreino : null,
            loading: _registrando,
            fontSize: 17,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color cor) => Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: cor,
              )),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textFaint,
                letterSpacing: 1,
              )),
        ],
      );

  Widget _buildInfoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

/// Casca dos diálogos desta tela.
class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.children, required this.glow});

  final List<Widget> children;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.stroke, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: glow.withValues(alpha: 0.4),
                blurRadius: 46,
                spreadRadius: -12,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

// ── Diálogo de boas-vindas ────────────────────────────────────────────────────

class _WelcomeDialog extends StatefulWidget {
  final int dia;
  const _WelcomeDialog({required this.dia});

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      glow: AppColors.blue,
      children: [
        const GlowBadge(icon: Icons.fitness_center_rounded, size: 82),
        const SizedBox(height: 22),
        const GradientText(
          'Bora treinar!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Dia ${widget.dia} — você consegue!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
      ],
    );
  }
}

// ── Diálogo de conclusão de treino ────────────────────────────────────────────

class _WorkoutSuccessDialog extends StatefulWidget {
  final bool completo;
  final int qtdConcluidos;
  final int totalExercicios;

  const _WorkoutSuccessDialog({
    required this.completo,
    required this.qtdConcluidos,
    required this.totalExercicios,
  });

  @override
  State<_WorkoutSuccessDialog> createState() => _WorkoutSuccessDialogState();
}

class _WorkoutSuccessDialogState extends State<_WorkoutSuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final completo = widget.completo;

    return _DialogShell(
      glow: completo ? AppColors.success : AppColors.blue,
      children: [
        GlowBadge(
          icon: completo ? Icons.emoji_events_rounded : Icons.check_rounded,
          size: 84,
          glowColor: completo ? AppColors.success : AppColors.blue,
          gradient: completo
              ? const LinearGradient(
                  colors: [AppColors.success, AppColors.cyan])
              : AppColors.brand,
        ),
        const SizedBox(height: 22),
        GradientText(
          completo ? 'Treino Completo!' : 'Treino Registrado!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.qtdConcluidos} de ${widget.totalExercicios} exercícios concluídos',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
      ],
    );
  }
}
