import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const ProfileScreen({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color bgCream    = Color(0xFFF5E6BE);
  static const Color inkBrown   = Color(0xFF3D2B1F);
  static const Color vintageRed = Color(0xFFBC4749);

  late Future<_PerfilData> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregarDados();
  }

  Future<_PerfilData> _carregarDados() async {
    final results = await Future.wait([
      http.get(Uri.parse('$baseUrl/api/usuarios/${widget.idUsuario}')),
      http.get(Uri.parse('$baseUrl/api/frequencias/usuario/${widget.idUsuario}/semanal')),
      http.get(Uri.parse('$baseUrl/api/lesoes/')),
    ]);

    if (results[0].statusCode != 200) throw Exception('Erro ao carregar perfil');

    final usuario    = jsonDecode(results[0].body) as Map<String, dynamic>;
    final frequencia = results[1].statusCode == 200
        ? jsonDecode(results[1].body) as List
        : <dynamic>[];
    final lesoes = results[2].statusCode == 200
        ? (jsonDecode(results[2].body) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return _PerfilData(usuario: usuario, frequencia: frequencia, lesoes: lesoes);
  }

  Future<void> _abrirEdicaoPreferencias(Map<String, dynamic> u, List<Map<String, dynamic>> lesoes) async {
    const objetivoOpcoes = {
      'Ganho de Força': 'forca',
      'Definição': 'hipertrofia',
      'Perder Gordura': 'emagrecimento',
      'Condicionamento': 'condicionamento',
    };
    const focoOpcoes = {
      'Equilibrado': 'full_body',
      'Superiores': 'superiores',
      'Inferiores': 'inferiores',
    };

    String? objetivo = u['objetivo'] as String?;
    String? foco = u['foco'] as String?;
    int? qtdDias = u['qtd_dias'] as int?;
    final pesoCtrl = TextEditingController(text: u['peso']?.toString() ?? '');
    final alturaCtrl = TextEditingController(text: u['altura']?.toString() ?? '');
    bool salvando = false;
    Set<int> selectedLesoes = (u['ids_lesoes'] as List? ?? []).map((e) => e as int).toSet();
    final nenhumaId = lesoes.isNotEmpty
        ? (lesoes.firstWhere(
              (l) => l['nm_lesao'] == 'Nenhuma',
              orElse: () => {'id_lesao': -1},
            )['id_lesao'] as int)
        : -1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: inkBrown, width: 2.5),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          InputDecoration deco(String label) => InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: inkBrown, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: inkBrown, width: 3),
            ),
          );

          Widget buildLesoesPicker() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lesoes.map((l) {
              final id = l['id_lesao'] as int;
              final nome = l['nm_lesao'] as String;
              final sel = selectedLesoes.contains(id);
              return FilterChip(
                label: Text(
                  nome,
                  style: TextStyle(
                    color: sel ? bgCream : inkBrown,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                selected: sel,
                onSelected: (val) => setLocal(() {
                  if (id == nenhumaId) {
                    selectedLesoes.clear();
                    if (val) { selectedLesoes.add(id); }
                  } else {
                    selectedLesoes.remove(nenhumaId);
                    if (val) { selectedLesoes.add(id); }
                    else { selectedLesoes.remove(id); }
                  }
                }),
                selectedColor: vintageRed,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                side: BorderSide(
                  color: sel ? inkBrown : inkBrown.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                checkmarkColor: bgCream,
                showCheckmark: false,
              );
            }).toList(),
          );

          Future<void> salvar() async {
            setLocal(() => salvando = true);
            bool fechou = false;
            try {
              final body = <String, dynamic>{};
              if (objetivo != null) body['objetivo'] = objetivo;
              if (foco != null) body['foco'] = foco;
              if (qtdDias != null) body['qtd_dias'] = qtdDias;
              final p = double.tryParse(pesoCtrl.text);
              final a = double.tryParse(alturaCtrl.text);
              if (p != null) body['peso'] = p;
              if (a != null) body['altura'] = a;
              body['ids_lesoes'] = selectedLesoes.toList();

              final resp = await http.put(
                Uri.parse('$baseUrl/api/usuarios/${widget.idUsuario}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              );

              if (!ctx.mounted) return;

              if (resp.statusCode == 200) {
                fechou = true;
                Navigator.of(ctx).pop();
                if (mounted) {
                  setState(() => _future = _carregarDados());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preferências atualizadas!'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Erro ao salvar.'), backgroundColor: vintageRed),
                );
              }
            } catch (e) {
              debugPrint('ERRO ao salvar preferências: $e');
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Erro: $e'), backgroundColor: vintageRed),
                );
              }
            } finally {
              if (!fechou && ctx.mounted) setLocal(() => salvando = false);
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: inkBrown.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Editar Preferências',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: inkBrown),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: objetivo,
                    decoration: deco('Objetivo'),
                    dropdownColor: bgCream,
                    iconEnabledColor: inkBrown,
                    items: objetivoOpcoes.entries.map((e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.key, style: const TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
                    )).toList(),
                    onChanged: (v) => setLocal(() => objetivo = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: foco,
                    decoration: deco('Foco do Treino'),
                    dropdownColor: bgCream,
                    iconEnabledColor: inkBrown,
                    items: focoOpcoes.entries.map((e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.key, style: const TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
                    )).toList(),
                    onChanged: (v) => setLocal(() => foco = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: qtdDias,
                    decoration: deco('Dias de treino por semana'),
                    dropdownColor: bgCream,
                    iconEnabledColor: inkBrown,
                    items: [2, 3, 4, 5].map((d) => DropdownMenuItem(
                      value: d,
                      child: Text('$d dias', style: const TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
                    )).toList(),
                    onChanged: (v) => setLocal(() => qtdDias = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: pesoCtrl,
                          style: const TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                          decoration: deco('Peso (kg)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: alturaCtrl,
                          style: const TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                          decoration: deco('Altura (m)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Lesões / Restrições',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: inkBrown),
                  ),
                  const SizedBox(height: 8),
                  buildLesoesPicker(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vintageRed,
                      foregroundColor: bgCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: inkBrown, width: 2.5),
                      ),
                    ),
                    child: salvando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: bgCream, strokeWidth: 2.5))
                        : const Text('SALVAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_PerfilData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: vintageRed));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar perfil.', style: TextStyle(color: inkBrown)),
            );
          }

          final dados = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(dados.usuario, dados.lesoes),
                _buildInfoCards(dados.usuario),
                _buildGrafico(dados.frequencia),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header com avatar e nome ──────────────────────────────────────────────

  Widget _buildHeader(Map<String, dynamic> u, List<Map<String, dynamic>> lesoes) {
    final iniciais = (u['nm_usuario'] as String)
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      color: bgCream,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: inkBrown,
                      ),
                    ),
                    Text(
                      u['em_usuario'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: inkBrown.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: inkBrown, size: 22),
                tooltip: 'Editar preferências',
                onPressed: () => _abrirEdicaoPreferencias(u, lesoes),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Avatar com iniciais
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: vintageRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: inkBrown, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    iniciais,
                    style: const TextStyle(
                      color: bgCream,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 3, color: inkBrown),
        ],
      ),
    );
  }

  // ── Cards de informações do usuário ──────────────────────────────────────

  Widget _buildInfoCards(Map<String, dynamic> u) {
    final labels = {
      'Objetivo':    _formatarObjetivo(u['objetivo']),
      'Foco':        _formatarFoco(u['foco']),
      'Dias/semana': '${u['qtd_dias'] ?? '-'}',
      'Peso':        u['peso'] != null ? '${u['peso']} kg' : '-',
      'Altura':      u['altura'] != null ? '${u['altura']} m' : '-',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: labels.entries.map((e) => _buildInfoChip(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inkBrown, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
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
      ),
    );
  }

  // ── Gráfico de frequência semanal ────────────────────────────────────────

  Widget _buildGrafico(List frequencia) {
    final treinou = frequencia.where((d) => d['treinou'] == true).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: inkBrown, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(3, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frequência Semanal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: inkBrown),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: treinou > 0 ? vintageRed : inkBrown.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$treinou dias',
                    style: const TextStyle(
                      color: bgCream,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: frequencia.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum treino registrado ainda.',
                        style: TextStyle(color: inkBrown.withValues(alpha: 0.5)),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: _maxY(frequencia),
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: inkBrown.withValues(alpha: 0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= frequencia.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    frequencia[idx]['dia_semana'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: inkBrown.withValues(alpha: 0.7),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(frequencia.length, (i) {
                          final dia = frequencia[i];
                          final qtd = (dia['qtd_exercicios'] as num).toDouble();
                          final treinou = dia['treinou'] as bool;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: treinou ? (qtd == 0 ? 1 : qtd) : 0,
                                color: treinou ? vintageRed : inkBrown.withValues(alpha: 0.15),
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Legenda
            Row(
              children: [
                _buildLegendaDot(vintageRed),
                const SizedBox(width: 4),
                Text('Treinou', style: TextStyle(fontSize: 11, color: inkBrown.withValues(alpha: 0.7))),
                const SizedBox(width: 16),
                _buildLegendaDot(inkBrown.withValues(alpha: 0.15)),
                const SizedBox(width: 4),
                Text('Sem treino', style: TextStyle(fontSize: 11, color: inkBrown.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaDot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      );

  double _maxY(List frequencia) {
    final max = frequencia
        .map((d) => (d['qtd_exercicios'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    return max < 5 ? 6 : max + 2;
  }

  // ── Formatadores ─────────────────────────────────────────────────────────

  String _formatarObjetivo(String? v) => {
        'hipertrofia':     'Definição',
        'forca':           'Força',
        'emagrecimento':   'Emagrecer',
        'condicionamento': 'Condicionamento',
      }[v] ?? (v ?? '-');

  String _formatarFoco(String? v) => {
        'full_body':  'Equilibrado',
        'superiores': 'Superiores',
        'inferiores': 'Inferiores',
      }[v] ?? (v ?? '-');
}

class _PerfilData {
  final Map<String, dynamic> usuario;
  final List frequencia;
  final List<Map<String, dynamic>> lesoes;
  const _PerfilData({required this.usuario, required this.frequencia, required this.lesoes});
}
