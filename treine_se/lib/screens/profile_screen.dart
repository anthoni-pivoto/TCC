import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/aviso_restricoes.dart';
import '../widgets/ui.dart';

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
  late Future<_PerfilData> _future;

  /// Sobe a cada salvamento. Serve de chave para o aviso de lesões, que tem
  /// estado próprio e precisa ser reconstruído do zero quando as lesões mudam.
  int _versaoPerfil = 0;

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

  Future<void> _abrirEdicaoPreferencias(
      Map<String, dynamic> u, List<Map<String, dynamic>> lesoes) async {
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget dropdown<T>({
            required String label,
            required T? value,
            required List<DropdownMenuItem<T>> items,
            required ValueChanged<T?> onChanged,
          }) =>
              DropdownButtonFormField<T>(
                initialValue: value,
                decoration: neonInput(label: label),
                dropdownColor: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.cyan, size: 22),
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                items: items,
                onChanged: onChanged,
              );

          Widget buildLesoesPicker() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lesoes.map((l) {
              final id = l['id_lesao'] as int;
              final nome = l['nm_lesao'] as String;
              final sel = selectedLesoes.contains(id);
              return NeonChip(
                label: nome,
                selected: sel,
                fontSize: 11.5,
                onTap: () => setLocal(() {
                  final val = !sel;
                  if (id == nenhumaId) {
                    selectedLesoes.clear();
                    if (val) { selectedLesoes.add(id); }
                  } else {
                    selectedLesoes.remove(nenhumaId);
                    if (val) { selectedLesoes.add(id); }
                    else { selectedLesoes.remove(id); }
                  }
                }),
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
                  setState(() {
                    _future = _carregarDados();
                    _versaoPerfil++;
                  });
                  _aviso('Preferências atualizadas!', AppColors.success);
                }
              } else {
                _avisoEm(ctx, 'Erro ao salvar.', AppColors.danger);
              }
            } catch (e) {
              debugPrint('ERRO ao salvar preferências: $e');
              if (ctx.mounted) {
                _avisoEm(ctx, 'Erro: $e', AppColors.danger);
              }
            } finally {
              if (!fechou && ctx.mounted) setLocal(() => salvando = false);
            }
          }

          return SheetShell(
            scrollable: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GradientText(
                  'Editar Preferências',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 22),
                dropdown<String>(
                  label: 'Objetivo',
                  value: objetivo,
                  items: objetivoOpcoes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => objetivo = v),
                ),
                const SizedBox(height: 14),
                dropdown<String>(
                  label: 'Foco do Treino',
                  value: foco,
                  items: focoOpcoes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => foco = v),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Dias de treino por semana'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [2, 3, 4, 5]
                      .map((d) => NeonChip(
                            label: '$d dias',
                            selected: qtdDias == d,
                            fontSize: 13,
                            onTap: () => setLocal(() => qtdDias = d),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: pesoCtrl,
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600),
                        decoration: neonInput(
                          label: 'Peso (kg)',
                          icon: Icons.monitor_weight_outlined,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: alturaCtrl,
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600),
                        decoration: neonInput(
                          label: 'Altura (m)',
                          icon: Icons.height_rounded,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const FieldLabel('Lesões / Restrições'),
                const SizedBox(height: 10),
                buildLesoesPicker(),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'SALVAR',
                  onPressed: salvando ? null : salvar,
                  loading: salvando,
                  fontSize: 17,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _aviso(String mensagem, Color cor) => _avisoEm(context, mensagem, cor);

  void _avisoEm(BuildContext ctx, String mensagem, Color cor) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: cor.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_PerfilData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.cyan));
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar perfil.',
                  style: TextStyle(color: AppColors.textDim)),
            );
          }

          final dados = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(dados.usuario, dados.lesoes),
                AvisoRestricoes(
                  key: ValueKey(_versaoPerfil),
                  idUsuario: widget.idUsuario,
                ),
                _buildInfoCards(dados.usuario),
                _buildGrafico(dados.frequencia),
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

    return ScreenHeader(
      title: 'Perfil',
      eyebrow: u['em_usuario'] as String?,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textDim),
            tooltip: 'Editar preferências',
            onPressed: () => _abrirEdicaoPreferencias(u, lesoes),
          ),
          const SizedBox(width: 4),
          // Avatar com iniciais
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.5),
                  blurRadius: 22,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                iniciais,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
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

    final entradas = labels.entries.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(entradas.length, (i) {
          // Mesma lógica de gradação da home: do ciano ao roxo ao longo da fila.
          final t = i / (entradas.length - 1);
          return _buildInfoChip(
            entradas[i].key,
            entradas[i].value,
            Color.lerp(AppColors.cyan, AppColors.purple, t)!,
          );
        }),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color acento) {
    return GlassCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      borderColor: acento.withValues(alpha: 0.30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: acento,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textFaint,
              letterSpacing: 1,
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        glowColor: AppColors.purple,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frequência Semanal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: treinou > 0 ? AppColors.brand : null,
                    color: treinou > 0
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: treinou > 0
                        ? [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: -3,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$treinou dias',
                    style: TextStyle(
                      color: treinou > 0 ? Colors.white : AppColors.textFaint,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 160,
              child: frequencia.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum treino registrado ainda.',
                        style: TextStyle(color: AppColors.textFaint),
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
                            color: Colors.white.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.bgElevated,
                            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                              '${rod.toY.toInt()} exercício(s)',
                              const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= frequencia.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    frequencia[idx]['dia_semana'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textFaint,
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
                                // Barra vertical em gradiente: a luz cresce
                                // junto com o valor.
                                gradient: treinou
                                    ? const LinearGradient(
                                        colors: [AppColors.purple, AppColors.cyan],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      )
                                    : null,
                                color: treinou
                                    ? null
                                    : Colors.white.withValues(alpha: 0.06),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            // Legenda
            Row(
              children: [
                _buildLegendaDot(AppColors.cyan),
                const SizedBox(width: 6),
                const Text('Treinou',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                const SizedBox(width: 18),
                _buildLegendaDot(Colors.white.withValues(alpha: 0.12)),
                const SizedBox(width: 6),
                const Text('Sem treino',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
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
