import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

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
  static const Color bgCream    = Color(0xFFF5E6BE);
  static const Color inkBrown   = Color(0xFF3D2B1F);
  static const Color vintageRed = Color(0xFFBC4749);
  static const Color greenCheck = Color(0xFF4CAF50);

  late Future<Map<String, Map<String, dynamic>>> _firestoreFuture;

  // índices dos exercícios marcados como concluídos
  final Set<int> _concluidos = {};
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _firestoreFuture = _carregarDadosFirestore();
  }

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
          final response = await http.get(
            Uri.parse('$baseUrl/api/exercicios/detalhe/$slug'),
          );
          if (response.statusCode == 200) {
            return MapEntry(slug, jsonDecode(response.body) as Map<String, dynamic>);
          }
        } catch (_) {}
        return MapEntry(slug, <String, dynamic>{});
      }),
    );

    return Map.fromEntries(resultados);
  }

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
        await _mostrarSucessoTreino(
          completo: completo,
          qtd: qtdConcluidos,
          total: exercicios.length,
        );
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

  Future<void> _mostrarSucessoTreino({
    required bool completo,
    required int qtd,
    required int total,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => _WorkoutSuccessDialog(
        completo: completo,
        qtdConcluidos: qtd,
        totalExercicios: total,
      ),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

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
              SliverToBoxAdapter(
                child: _buildRegistrarButton(exercicios.length),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRegistrarButton(int totalExercicios) {
    final int qtd = _concluidos.length;
    final bool algumMarcado = qtd > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        children: [
          // Contador de progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$qtd / $totalExercicios',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: inkBrown,
                ),
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
                  side: BorderSide(color: algumMarcado ? inkBrown : Colors.transparent, width: 2.5),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(Map<String, dynamic> ex, Map<String, dynamic> fs, int index) {
    final gifUrl = ex['slug_firebase'] != null && (ex['slug_firebase'] as String).isNotEmpty
        ? '$baseUrl/api/exercicios/gif/${ex['slug_firebase']}'
        : null;
    final equipment   = fs['equipamento'] as String?;
    final dicas       = (fs['dicas_execucao'] as List?)?.cast<String>() ?? [];
    final secundarios = (fs['musculos_secundarios'] as List?)?.cast<String>() ?? [];
    final concluido   = _concluidos.contains(index);

    return GestureDetector(
      onTap: () => setState(() {
        if (concluido) {
          _concluidos.remove(index);
        } else {
          _concluidos.add(index);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: concluido
              ? greenCheck.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: concluido ? greenCheck : inkBrown,
            width: 2.5,
          ),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(3, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GIF
            if (gifUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: Image.network(
                  Uri.encodeFull(gifUrl),
                  height: 200,
                  fit: BoxFit.cover,
                  headers: const {'Accept': 'image/gif,image/*'},
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator(color: vintageRed)),
                        ),
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 100,
                    child: Center(child: Icon(Icons.broken_image, color: inkBrown, size: 40)),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome + checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Número / check
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
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
                                    color: bgCream,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ex['nm_exercicio'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: inkBrown,
                            decoration: concluido ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      Icon(
                        concluido ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: concluido ? greenCheck : inkBrown.withValues(alpha: 0.4),
                        size: 24,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: inkBrown, thickness: 1),
                  const SizedBox(height: 8),

                  // Séries / Reps / Descanso
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: inkBrown),
                    ),
                    const SizedBox(height: 6),
                    ...dicas.map(
                      (dica) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: vintageRed, fontWeight: FontWeight.w900)),
                            Expanded(
                              child: Text(
                                dica,
                                style: TextStyle(fontSize: 13, color: inkBrown.withValues(alpha: 0.85)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: vintageRed),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: inkBrown.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: inkBrown.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: inkBrown.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

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
            color: const Color(0xFFF5E6BE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3D2B1F), width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(4, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.completo ? const Color(0xFFBC4749) : const Color(0xFF3D2B1F),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.completo ? Icons.emoji_events : Icons.check,
                  color: const Color(0xFFF5E6BE),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.completo ? 'Treino Completo!' : 'Treino Registrado!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.qtdConcluidos} de ${widget.totalExercicios} exercícios concluídos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF3D2B1F).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
