import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/notification_service.dart';

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
  static const Color bgCream    = Color(0xFFEDF2F7);
  static const Color inkBrown   = Color(0xFF2D4F6B);
  static const Color vintageRed = Color(0xFF7B9EC5);
  static const Color greenCheck = Color(0xFF4CAF50);

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
      barrierColor: Colors.black.withValues(alpha: 0.65),
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
        await _mostrarSucessoTreino(completo: completo, qtd: qtdConcluidos, total: exercicios.length);
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao registrar treino.'), backgroundColor: vintageRed),
        );
      }
    } catch (e) {
      debugPrint('ERRO ao registrar treino: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: vintageRed),
        );
      }
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  Future<void> _mostrarSucessoTreino({required bool completo, required int qtd, required int total}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) =>
          _WorkoutSuccessDialog(completo: completo, qtdConcluidos: qtd, totalExercicios: total),
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
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: inkBrown, size: 28),
        title: Text(
          'Dia $dia',
          style: const TextStyle(color: inkBrown, fontWeight: FontWeight.w900, fontSize: 24),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3.0),
          child: ColoredBox(color: inkBrown, child: SizedBox(height: 3)),
        ),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _firestoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: vintageRed));
          }
          final firestoreData = snapshot.data ?? {};
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ex = exercicios[index] as Map<String, dynamic>;
                      final fsData = firestoreData[ex['slug_firebase']] ?? {};
                      return _buildExercicioCard(ex, fsData, index);
                    },
                    childCount: exercicios.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildRegistrarButton(exercicios.length)),
            ],
          );
        },
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: concluido ? greenCheck.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: concluido ? greenCheck : inkBrown, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(3, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: concluido ? greenCheck : vintageRed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: concluido
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: bgCream, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nome + resumo de séries
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: inkBrown,
                              decoration: concluido ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${ex['qtd_series']}x${ex['qtd_repeticoes']}  ·  ${ex['tempo_descanso_s']}s descanso',
                            style: TextStyle(
                              fontSize: 12,
                              color: inkBrown.withValues(alpha: 0.6),
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
                          concluido ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: concluido ? greenCheck : inkBrown.withValues(alpha: 0.35),
                          size: 26,
                        ),
                      ),
                    ),

                    // Seta expand
                    AnimatedRotation(
                      turns: expandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: inkBrown.withValues(alpha: 0.5),
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
                        Divider(
                          color: inkBrown.withValues(alpha: 0.2),
                          height: 1,
                          thickness: 1,
                        ),

                        // GIF
                        if (gifUrl != null)
                          Image.network(
                            Uri.encodeFull(gifUrl),
                            height: 200,
                            fit: BoxFit.cover,
                            headers: const {'Accept': 'image/gif,image/*'},
                            loadingBuilder: (_, child, progress) => progress == null
                                ? child
                                : const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(color: vintageRed),
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 80,
                              child: Center(
                                child: Icon(Icons.broken_image, color: inkBrown, size: 40),
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat('Séries', '${ex['qtd_series']}'),
                                  _buildStat('Reps', '${ex['qtd_repeticoes']}'),
                                  _buildStat('Descanso', '${ex['tempo_descanso_s']}s'),
                                ],
                              ),

                              if (equipment != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.fitness_center, equipment),
                              ],
                              if (secundarios.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(Icons.accessibility_new, secundarios.join(', ')),
                              ],
                              if (dicas.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Dicas de execução',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: inkBrown,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...dicas.map((dica) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          color: vintageRed, fontWeight: FontWeight.w900),
                                      ),
                                      Expanded(
                                        child: Text(
                                          dica,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: inkBrown.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],

                              // Timer de descanso
                              const SizedBox(height: 16),
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
        color: inkBrown.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inkBrown.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: timerAtivo ? vintageRed : inkBrown.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Descanso entre séries',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: inkBrown.withValues(alpha: 0.75),
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
                    color: timerAtivo
                        ? vintageRed
                        : (encerrado ? greenCheck : inkBrown),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Botão iniciar / parar / repetir
              GestureDetector(
                onTap: () => timerAtivo
                    ? _cancelarTimer(index)
                    : _iniciarTimer(index, tempoDescanso, nome),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: timerAtivo ? inkBrown : vintageRed,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: inkBrown, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        timerAtivo ? Icons.stop : Icons.play_arrow,
                        color: bgCream,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timerAtivo ? 'Parar' : (encerrado ? 'Repetir' : 'Iniciar'),
                        style: const TextStyle(
                          color: bgCream, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Barra de progresso (só enquanto ativo)
          if (timerAtivo && timerSegundos != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresso,
                backgroundColor: inkBrown.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(vintageRed),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$qtd / $totalExercicios',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: inkBrown),
              ),
              const SizedBox(width: 8),
              Text(
                'exercícios concluídos',
                style: TextStyle(
                  fontSize: 13,
                  color: inkBrown.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: algumMarcado && !_registrando ? _registrarTreino : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: algumMarcado ? vintageRed : inkBrown.withValues(alpha: 0.3),
                foregroundColor: bgCream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: algumMarcado ? 6 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: algumMarcado ? inkBrown : Colors.transparent, width: 2.5),
                ),
              ),
              child: _registrando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: bgCream, strokeWidth: 2.5),
                    )
                  : const Text(
                      'REGISTRAR TREINO',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: vintageRed)),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inkBrown.withValues(alpha: 0.7),
              )),
        ],
      );

  Widget _buildInfoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: inkBrown.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: inkBrown.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
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
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2D4F6B), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(4, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF7B9EC5), shape: BoxShape.circle),
                child: const Icon(Icons.fitness_center, color: Color(0xFFEDF2F7), size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bora treinar!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D4F6B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Dia ${widget.dia} — você consegue!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D4F6B).withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2D4F6B), width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(4, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.completo
                      ? const Color(0xFF7B9EC5)
                      : const Color(0xFF2D4F6B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.completo ? Icons.emoji_events : Icons.check,
                  color: const Color(0xFFEDF2F7),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.completo ? 'Treino Completo!' : 'Treino Registrado!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D4F6B)),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.qtdConcluidos} de ${widget.totalExercicios} exercícios concluídos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D4F6B).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
