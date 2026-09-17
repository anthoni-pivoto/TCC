import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Aviso fixo para quem registrou alguma lesão.
///
/// Aparece sempre que há lesão marcada — não só nos casos extremos — porque o
/// usuário precisa saber quais músculos o app passou a tratar com cuidado ao
/// montar a ficha. Pode ser recolhido para não atrapalhar a rolagem, mas nunca
/// dispensado: quem decide o que fazer com uma lesão é um profissional de
/// saúde, e essa ressalva tem de continuar ao alcance da mão.
class AvisoRestricoes extends StatefulWidget {
  const AvisoRestricoes({super.key, required this.idUsuario});

  final int idUsuario;

  @override
  State<AvisoRestricoes> createState() => _AvisoRestricoesState();
}

class _AvisoRestricoesState extends State<AvisoRestricoes> {
  List<String> _lesoes = const [];
  List<String> _gruposAfetados = const [];
  List<String> _gruposSemExercicio = const [];
  bool _expandido = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(AvisoRestricoes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idUsuario != widget.idUsuario) _carregar();
  }

  Future<void> _carregar() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/usuarios/${widget.idUsuario}/restricoes'))
          .timeout(const Duration(seconds: 15));
      if (!mounted || resp.statusCode != 200) return;

      final corpo = jsonDecode(resp.body) as Map<String, dynamic>;
      List<String> lista(String chave) =>
          (corpo[chave] as List? ?? const []).map((g) => g.toString()).toList();

      setState(() {
        _lesoes = lista('lesoes');
        _gruposAfetados = lista('grupos_afetados');
        _gruposSemExercicio = lista('grupos_sem_exercicio');
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
    if (_lesoes.isEmpty) return const SizedBox.shrink();

    final bool grave = _gruposSemExercicio.isNotEmpty;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: EdgeInsets.zero,
      borderColor: AppColors.warning.withValues(alpha: 0.4),
      glowColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCabecalho(grave),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expandido
                ? _buildCorpo(grave)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// Sempre visível. Recolhido, resume em uma linha quais músculos estão em
  /// jogo — o aviso some da tela sem sumir da consciência.
  Widget _buildCabecalho(bool grave) {
    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 12, _expandido ? 4 : 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.warning,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atenção ao seu caso',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (!_expandido) ...[
                    const SizedBox(height: 3),
                    Text(
                      _gruposAfetados.isEmpty
                          ? '${_lesoes.length} lesão(ões) registrada(s)'
                          : 'Cuidado com ${_listar(_gruposAfetados)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: grave
                            ? AppColors.warning
                            : AppColors.textDim,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedRotation(
              turns: _expandido ? 0.5 : 0,
              duration: const Duration(milliseconds: 260),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.warning,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorpo(bool grave) {
    const corpo = TextStyle(
      fontSize: 13.5,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textDim,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lesoes.length == 1
                ? 'Você registrou ${_lesoes.first.toLowerCase()}.'
                : 'Você registrou ${_lesoes.length} lesões: ${_listar(_lesoes)}.',
            style: corpo,
          ),
          if (_gruposAfetados.isNotEmpty) ...[
            const SizedBox(height: 12),
            const FieldLabel('Músculos envolvidos'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _gruposAfetados
                  .map((g) => _ChipMusculo(
                        nome: g,
                        // Sem exercício liberado é outro patamar de risco, e a
                        // etiqueta precisa deixar isso à vista.
                        semExercicio: _gruposSemExercicio.contains(g),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            grave
                ? 'Para ${_listar(_gruposSemExercicio)} não encontramos nenhum '
                    'exercício que possamos indicar com segurança, então esses '
                    'músculos ficaram de fora da sua ficha.'
                : 'Os exercícios desses músculos foram ajustados ou substituídos '
                    'na sua ficha para reduzir o risco.',
            style: corpo,
          ),
          const SizedBox(height: 8),
          const Text(
            'Recomendamos buscar acompanhamento profissional — fortalecimento, '
            'alongamento ou fisioterapia — para seguir com a atenção '
            'especializada que você merece.',
            style: corpo,
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.warning.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 12),
          const Text(
            'O Treine-se auxilia na criação de hábitos saudáveis e não '
            'substitui a avaliação de um profissional de saúde.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de músculo afetado. Preenchida quando não sobrou exercício algum
/// para aquele grupo, só contornada quando a ficha apenas foi ajustada.
class _ChipMusculo extends StatelessWidget {
  const _ChipMusculo({required this.nome, required this.semExercicio});

  final String nome;
  final bool semExercicio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: semExercicio ? 0.18 : 0.07),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: semExercicio ? 0.6 : 0.28),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (semExercicio) ...[
            const Icon(Icons.block_rounded, size: 12, color: AppColors.warning),
            const SizedBox(width: 5),
          ],
          Text(
            nome,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: semExercicio ? FontWeight.w800 : FontWeight.w600,
              color: semExercicio
                  ? AppColors.warning
                  : AppColors.warning.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
