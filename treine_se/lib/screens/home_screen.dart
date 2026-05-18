import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'treino_detalhe_screen.dart';
import '../config/app_config.dart';

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
  static const Color bgCream    = Color(0xFFF5E6BE);
  static const Color inkBrown   = Color(0xFF3D2B1F);
  static const Color vintageRed = Color(0xFFBC4749);

  List<dynamic> _treinos = [];
  bool _loading = true;
  String? _erro;

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
        });
      } else {
        setState(() { _erro = 'Erro ao carregar treinos.'; _loading = false; });
      }
    } catch (e) {
      setState(() { _erro = 'Sem conexão com o servidor.'; _loading = false; });
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
          Text(
            'Olá, ${widget.nomeUsuario.split(' ').first}!',
            style: const TextStyle(
              fontSize: 14,
              color: inkBrown,
              fontWeight: FontWeight.w600,
            ),
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
      itemCount: _treinos.length,
      itemBuilder: (context, index) => _buildTreinoCard(_treinos[index]),
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
