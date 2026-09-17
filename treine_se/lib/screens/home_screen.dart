import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'treino_detalhe_screen.dart';
import '../config/app_config.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aviso_restricoes.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const HomeScreen({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _treinos = [];
  bool _loading = true;
  String? _erro;
  bool _mostrarBanner = false;
  bool _agendandoTreinos = false;

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/treinos/usuario/${widget.idUsuario}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _treinos = jsonDecode(response.body);
          _loading = false;
          _mostrarBanner = _treinos.isNotEmpty;
        });
      } else {
        setState(() {
          _erro = 'Erro ao carregar treinos.';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ERRO ao carregar treinos: $e');
      setState(() {
        _erro = 'Erro: $e';
        _loading = false;
      });
    }
  }

  Future<void> _abrirBottomSheetAgendamento() async {
    TimeOfDay horarioSelecionado = const TimeOfDay(hour: 7, minute: 0);
    int duracaoMinutos = 60;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GradientText(
                'Agendar Treinos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Seus ${_treinos.length} treino(s) serão adicionados toda semana no calendário:\n'
                '${CalendarService.nomeDosDias(_treinos.cast<Map<String, dynamic>>())}',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel('Horário'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: horarioSelecionado,
                  );
                  if (picked != null) {
                    setModalState(() => horarioSelecionado = picked);
                  }
                },
                child: GlassCard(
                  radius: AppRadius.md,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.cyan, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        horarioSelecionado.format(ctx),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.textFaint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const FieldLabel('Duração estimada'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 45, 60, 90]
                    .map((min) => NeonChip(
                          label: '${min}min',
                          selected: duracaoMinutos == min,
                          onTap: () =>
                              setModalState(() => duracaoMinutos = min),
                          fontSize: 13,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'CONFIRMAR',
                icon: Icons.calendar_month_rounded,
                fontSize: 16,
                onPressed: () {
                  Navigator.pop(ctx);
                  _agendarTreinos(horarioSelecionado, duracaoMinutos);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _agendarTreinos(TimeOfDay horario, int duracaoMinutos) async {
    setState(() => _agendandoTreinos = true);
    try {
      final sucesso = await CalendarService.agendarTreinos(
        treinos: _treinos.cast<Map<String, dynamic>>(),
        horario: horario,
        duracaoMinutos: duracaoMinutos,
      );
      if (!mounted) return;
      if (sucesso) {
        await NotificationService.agendarLembretesTreino(
          treinos: _treinos.cast<Map<String, dynamic>>(),
          horario: horario,
        );
        if (!mounted) return;
        setState(() => _mostrarBanner = false);
        _aviso('Treinos agendados com sucesso!', AppColors.success);
      } else {
        _aviso(
          'Não foi possível agendar. Verifique as permissões do calendário.',
          AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _agendandoTreinos = false);
    }
  }

  void _aviso(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            eyebrow: 'Olá, ${widget.nomeUsuario.split(' ').first}!',
            title: 'Seus Treinos',
            trailing: _treinos.isEmpty ? null : _botaoAgendar(),
          ),
          // Fica acima da lista, sempre visível, antes de qualquer treino.
          AvisoRestricoes(idUsuario: widget.idUsuario),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _botaoAgendar() {
    if (_agendandoTreinos) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
      );
    }
    return GestureDetector(
      onTap: _abrirBottomSheetAgendamento,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: -3,
            ),
          ],
        ),
        child: const Icon(Icons.calendar_month_rounded,
            color: AppColors.cyan, size: 20),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      );
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textFaint, size: 44),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 15),
              ),
              const SizedBox(height: 24),
              OutlineGlowButton(
                label: 'TENTAR NOVAMENTE',
                icon: Icons.refresh_rounded,
                onPressed: _carregarTreinos,
              ),
            ],
          ),
        ),
      );
    }
    if (_treinos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_rounded,
                color: AppColors.textFaint, size: 48),
            SizedBox(height: 14),
            Text(
              'Nenhum treino encontrado.',
              style: TextStyle(color: AppColors.textDim, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarTreinos,
      color: AppColors.cyan,
      backgroundColor: AppColors.bgElevated,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        itemCount: _treinos.length + (_mostrarBanner ? 1 : 0),
        itemBuilder: (context, index) {
          if (_mostrarBanner && index == 0) {
            return _buildBannerAgendamento();
          }
          final treinoIndex = _mostrarBanner ? index - 1 : index;
          return _buildTreinoCard(_treinos[treinoIndex], treinoIndex);
        },
      ),
    );
  }

  Widget _buildBannerAgendamento() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      radius: AppRadius.md,
      borderColor: AppColors.cyan.withValues(alpha: 0.35),
      glowColor: AppColors.cyan,
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded,
              color: AppColors.cyan, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agendar treinos?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adicione seus ${_treinos.length} treino(s) ao calendário semanal',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDim,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _abrirBottomSheetAgendamento,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const GradientText(
              'Agendar',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _mostrarBanner = false),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
                  Icon(Icons.close_rounded, size: 16, color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreinoCard(Map<String, dynamic> treino, int posicao) {
    final List exercicios = treino['exercicios'] ?? [];
    final int dia = treino['dia_treino'];
    final gruposUnicos = exercicios
        .map((e) => e['grupo_muscular'] as String)
        .toSet()
        .toList();

    // Cada card puxa um pouco mais para o roxo conforme desce a lista, o que
    // dá ritmo visual sem inventar cores fora da paleta.
    final double t = _treinos.length <= 1
        ? 0
        : (posicao / (_treinos.length - 1)).clamp(0.0, 1.0);
    final Color acento = Color.lerp(AppColors.cyan, AppColors.purple, t)!;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      glowColor: acento,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TreinoDetalheScreen(
            treino: treino,
            idUsuario: widget.idUsuario,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selo do dia
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              gradient: LinearGradient(
                colors: [
                  acento.withValues(alpha: 0.9),
                  acento.withValues(alpha: 0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: acento.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'DIA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '$dia',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gruposUnicos.isEmpty
                      ? 'Treino do dia'
                      : gruposUnicos.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded,
                        size: 13, color: acento),
                    const SizedBox(width: 5),
                    Text(
                      '${exercicios.length} exercícios',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: acento, size: 15),
        ],
      ),
    );
  }
}
