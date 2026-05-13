import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

const String _baseUrl = "http://192.168.0.12:8000";

class TreinoDetalheScreen extends StatefulWidget {
  final Map<String, dynamic> treino;

  const TreinoDetalheScreen({super.key, required this.treino});

  @override
  State<TreinoDetalheScreen> createState() => _TreinoDetalheScreenState();
}

class _TreinoDetalheScreenState extends State<TreinoDetalheScreen> {
  static const Color bgCream    = Color(0xFFF5E6BE);
  static const Color inkBrown   = Color(0xFF3D2B1F);
  static const Color vintageRed = Color(0xFFBC4749);

  // Mapa slug → dados do Firestore
  late Future<Map<String, Map<String, dynamic>>> _firestoreFuture;

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
            Uri.parse('$_baseUrl/api/exercicios/detalhe/$slug'),
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
          style: const TextStyle(
            color: inkBrown,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3.0),
          child: ColoredBox(
            color: inkBrown,
            child: SizedBox(height: 3),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _firestoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: vintageRed));
          }
          final firestoreData = snapshot.data ?? {};
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercicios.length,
            itemBuilder: (context, index) {
              final ex = exercicios[index] as Map<String, dynamic>;
              final fsData = firestoreData[ex['slug_firebase']] ?? {};
              return _buildExercicioCard(ex, fsData, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildExercicioCard(
    Map<String, dynamic> ex,
    Map<String, dynamic> fs,
    int numero,
  ) {
    final gifUrl = ex['slug_firebase'] != null && (ex['slug_firebase'] as String).isNotEmpty
        ? '$_baseUrl/api/exercicios/gif/${ex['slug_firebase']}'
        : null;
    final equipment = fs['equipamento'] as String?;
    final dicas     = (fs['dicas_execucao'] as List?)?.cast<String>() ?? [];
    final secundarios = (fs['musculos_secundarios'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inkBrown, width: 2.5),
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
                errorBuilder: (context, error, _) {
                  debugPrint('Erro ao carregar GIF: $error\nURL: $gifUrl');
                  return const SizedBox(
                    height: 100,
                    child: Center(child: Icon(Icons.broken_image, color: inkBrown, size: 40)),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + número
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: vintageRed, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$numero',
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: inkBrown,
                        ),
                      ),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: inkBrown,
                    ),
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
                              style: TextStyle(
                                fontSize: 13,
                                color: inkBrown.withValues(alpha: 0.85),
                              ),
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
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: vintageRed,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: inkBrown.withValues(alpha: 0.7),
          ),
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
}
