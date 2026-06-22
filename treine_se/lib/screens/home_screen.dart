import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'treino_detalhe_screen.dart';
import '../config/app_config.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';

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
  static const Color bgCream    = Color(0xFFEDF2F7);
  static const Color inkBrown   = Color(0xFF2D4F6B);
  static const Color vintageRed = Color(0xFF7B9EC5);

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
    setState(() { _loading = true; _erro = null; });
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
        setState(() { _erro = 'Erro ao carregar treinos.'; _loading = false; });
      }
    } catch (e) {
      debugPrint('ERRO ao carregar treinos: $e');
      setState(() { _erro = 'Erro: $e'; _loading = false; });
    }
  }

  Future<void> _abrirBottomSheetAgendamento() async {
    TimeOfDay horarioSelecionado = const TimeOfDay(hour: 7, minute: 0);
    int duracaoMinutos = 60;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: inkBrown.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Agendar Treinos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: inkBrown),
              ),
              const SizedBox(height: 4),
              Text(
                'Seus ${_treinos.length} treino(s) serão adicionados toda semana no calendário:\n'
                '${CalendarService.nomeDosDias(_treinos.cast<Map<String, dynamic>>())}',
                style: TextStyle(fontSize: 13, color: inkBrown.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Horário',
                style: TextStyle(fontWeight: FontWeight.w700, color: inkBrown, fontSize: 15),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: horarioSelecionado,
                  );
                  if (picked != null) setModalState(() => horarioSelecionado = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: inkBrown, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: vintageRed),
                      const SizedBox(width: 10),
                      Text(
                        horarioSelecionado.format(ctx),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: inkBrown,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit, size: 16, color: inkBrown.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Duração estimada',
                style: TextStyle(fontWeight: FontWeight.w700, color: inkBrown, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [30, 45, 60, 90].map((min) => ChoiceChip(
                  label: Text('${min}min'),
                  selected: duracaoMinutos == min,
                  onSelected: (_) => setModalState(() => duracaoMinutos = min),
                  selectedColor: vintageRed,
                  labelStyle: TextStyle(
                    color: duracaoMinutos == min ? bgCream : inkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: bgCream,
                  side: const BorderSide(color: inkBrown, width: 1.5),
                )).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _agendarTreinos(horarioSelecionado, duracaoMinutos);
                  },
                  icon: const Icon(Icons.calendar_month, color: bgCream),
                  label: const Text(
                    'Confirmar Agendamento',
                    style: TextStyle(
                      color: bgCream,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vintageRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Treinos agendados com sucesso!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível agendar. Verifique as permissões do calendário.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _agendandoTreinos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: bgCream,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Olá, ${widget.nomeUsuario.split(' ').first}!',
                style: const TextStyle(
                  fontSize: 14,
                  color: inkBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_treinos.isNotEmpty)
                _agendandoTreinos
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: vintageRed,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        onPressed: _abrirBottomSheetAgendamento,
                        icon: const Icon(Icons.calendar_month, color: vintageRed),
                        tooltip: 'Agendar treinos no calendário',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Seus Treinos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: inkBrown,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 3, color: inkBrown),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: vintageRed));
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!, style: const TextStyle(color: inkBrown, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarTreinos,
              style: ElevatedButton.styleFrom(backgroundColor: vintageRed),
              child: const Text('Tentar novamente', style: TextStyle(color: bgCream)),
            ),
          ],
        ),
      );
    }
    if (_treinos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum treino encontrado.',
          style: TextStyle(color: inkBrown, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _treinos.length + (_mostrarBanner ? 1 : 0),
      itemBuilder: (context, index) {
        if (_mostrarBanner && index == 0) {
          return _buildBannerAgendamento();
        }
        final treinoIndex = _mostrarBanner ? index - 1 : index;
        return _buildTreinoCard(_treinos[treinoIndex]);
      },
    );
  }

  Widget _buildBannerAgendamento() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vintageRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vintageRed, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: vintageRed, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agendar treinos?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: inkBrown,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Adicione seus ${_treinos.length} treino(s) ao calendário semanal',
                  style: TextStyle(fontSize: 11, color: inkBrown.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _abrirBottomSheetAgendamento,
            style: TextButton.styleFrom(
              foregroundColor: vintageRed,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Agendar',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _mostrarBanner = false),
            child: Icon(Icons.close, size: 16, color: inkBrown.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTreinoCard(Map<String, dynamic> treino) {
    final List exercicios = treino['exercicios'] ?? [];
    final int dia = treino['dia_treino'];
    final gruposUnicos = exercicios
        .map((e) => e['grupo_muscular'] as String)
        .toSet()
        .toList();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TreinoDetalheScreen(
            treino: treino,
            idUsuario: widget.idUsuario,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: inkBrown, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(3, 3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dia $dia',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: inkBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercicios.length} exercícios  •  ${gruposUnicos.join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: inkBrown.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: vintageRed, size: 18),
          ],
        ),
      ),
    );
  }
}
