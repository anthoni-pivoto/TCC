import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Aviso fixo para quando as lesões do usuário deixam algum grupo muscular sem
/// nenhum exercício liberado.
///
/// Não é dispensável de propósito: quando o app não tem o que prescrever com
/// segurança para uma região do corpo, quem decide o que fazer é um
/// profissional de saúde. Some sozinho quando não há grupo nessa situação.
class AvisoRestricoes extends StatefulWidget {
  const AvisoRestricoes({super.key, required this.idUsuario});

  final int idUsuario;

  @override
  State<AvisoRestricoes> createState() => _AvisoRestricoesState();
}

class _AvisoRestricoesState extends State<AvisoRestricoes> {
  static const Color _inkBrown = Color(0xFF2D4F6B);
  static const Color _fundo = Color(0xFFFDF3E3);
  static const Color _borda = Color(0xFFD9A441);
  static const Color _icone = Color(0xFFB4740B);

  List<String> _grupos = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/usuarios/${widget.idUsuario}/restricoes'))
          .timeout(const Duration(seconds: 15));
      if (!mounted || resp.statusCode != 200) return;

      final corpo = jsonDecode(resp.body) as Map<String, dynamic>;
      setState(() {
        _grupos = (corpo['grupos_sem_exercicio'] as List? ?? const [])
            .map((g) => g.toString())
            .toList();
      });
    } catch (_) {
      // Sem conexão o aviso apenas não aparece; não vale travar a tela por isso.
    }
  }

  /// "glúteos", "glúteos e isquiotibiais", "A, B e C"
  String _listar(List<String> itens) {
    if (itens.length == 1) return itens.first;
    return '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}';
  }

  @override
  Widget build(BuildContext context) {
    if (_grupos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borda, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: _icone, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Atenção ao seu caso',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _inkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Com base nas suas respostas, notamos que pode haver dificuldade '
            'para treinar ${_listar(_grupos)} com segurança.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: _inkBrown.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recomendamos buscar acompanhamento profissional — fortalecimento, '
            'alongamento ou fisioterapia — para seguir com a atenção '
            'especializada que você merece.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: _inkBrown.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _borda.withValues(alpha: 0.5), width: 1),
              ),
            ),
            child: Text(
              'O Treine-se auxilia na criação de hábitos saudáveis e não '
              'substitui a avaliação de um profissional de saúde.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: _inkBrown.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
