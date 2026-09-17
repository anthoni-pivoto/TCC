import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers para os campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Variáveis para armazenar as seleções dos Dropdowns
  String _selectedGoal = "forca";
  String _selectedFocus = "full_body";
  int _selectedDays = 4;

  bool _senhaVisivel = false;

  // label exibido -> valor enviado ao backend
  final Map<String, String> _goalOptions = {
    "Ganho de Força":  "forca",
    "Definição":       "hipertrofia",
    "Perder Gordura":  "emagrecimento",
    "Condicionamento": "condicionamento",
  };
  final Map<String, String> _focusOptions = {
    "Equilibrado":  "full_body",
    "Superiores":   "superiores",
    "Inferiores":   "inferiores",
  };
  final List<int> _daysOptions = [2, 3, 4, 5];

  // Trava o botão durante o cadastro: a geração do treino pela IA leva uns
  // 13 segundos, e sem isso o usuário toca de novo e cria dois cadastros.
  bool _enviando = false;

  // nome do campo no backend -> rótulo que o usuário reconhece
  static const Map<String, String> _rotulosCampos = {
    'nm_usuario': 'Nome',
    'em_usuario': 'E-mail',
    'pwd_usuario': 'Senha',
    'peso': 'Peso',
    'altura': 'Altura',
    'qtd_dias': 'Dias de treino',
    'objetivo': 'Objetivo',
    'foco': 'Foco',
  };

  List<Map<String, dynamic>> _lesoes = [];
  final Set<int> _selectedLesoes = {};
  bool _loadingLesoes = true;

  @override
  void initState() {
    super.initState();
    _carregarLesoes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _carregarLesoes() async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl/api/lesoes/'));
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _lesoes = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
          _loadingLesoes = false;
        });
      } else if (mounted) {
        setState(() => _loadingLesoes = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLesoes = false);
    }
  }

  Widget _buildLesoesPicker() {
    if (_loadingLesoes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.cyan,
            strokeWidth: 2,
          ),
        ),
      );
    }
    final nenhumaId = _lesoes.isNotEmpty
        ? (_lesoes.firstWhere(
              (l) => l['nm_lesao'] == 'Nenhuma',
              orElse: () => {'id_lesao': -1},
            )['id_lesao'] as int)
        : -1;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _lesoes.map((l) {
        final id = l['id_lesao'] as int;
        final nome = l['nm_lesao'] as String;
        final selected = _selectedLesoes.contains(id);
        return NeonChip(
          label: nome,
          selected: selected,
          fontSize: 11.5,
          onTap: () => setState(() {
            final val = !selected;
            if (id == nenhumaId) {
              _selectedLesoes.clear();
              if (val) { _selectedLesoes.add(id); }
            } else {
              _selectedLesoes.remove(nenhumaId);
              if (val) { _selectedLesoes.add(id); }
              else { _selectedLesoes.remove(id); }
            }
          }),
        );
      }).toList(),
    );
  }

  /// Confere os campos aqui mesmo. Evita uma ida ao servidor — que leva uns 13
  /// segundos por causa da geração do treino — só para descobrir que faltou
  /// preencher algo. Devolve null quando está tudo certo.
  String? _validarCampos() {
    if (_nameController.text.trim().isEmpty) {
      return 'Informe seu nome.';
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'O e-mail informado não parece válido.\n\nExemplo: nome@email.com';
    }
    if (_passwordController.text.length < 6) {
      return 'A senha precisa ter ao menos 6 caracteres.';
    }
    // Aceita vírgula: no Brasil se digita 1,80 com muito mais frequência.
    final peso = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (peso == null || peso <= 0) {
      return 'Informe um peso válido, em quilos.';
    }
    final altura = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (altura == null || altura <= 0) {
      return 'Informe uma altura válida, como 1,75.';
    }
    return null;
  }

  /// Traduz a resposta de erro do backend para uma frase legível.
  ///
  /// O FastAPI usa DUAS formas diferentes no campo `detail`: uma lista de erros
  /// de validação (HTTP 422) ou uma string simples (400, 401, 404). Tratar só
  /// uma delas era o que fazia o JSON cru aparecer na tela.
  String _mensagemDeErro(http.Response resposta) {
    try {
      final corpo = jsonDecode(resposta.body);
      final detalhe = corpo is Map ? corpo['detail'] : null;

      if (detalhe is List) {
        return detalhe.map((erro) {
          final loc = (erro['loc'] as List?) ?? const [];
          final campo = loc.isNotEmpty ? loc.last.toString() : '';
          final rotulo = _rotulosCampos[campo] ?? campo;
          final msg = (erro['msg'] ?? '').toString();

          if (msg.contains('@-sign') || msg.contains('valid email')) {
            return '$rotulo: informe um endereço válido, como nome@email.com';
          }
          if (msg.contains('Field required')) {
            return '$rotulo: campo obrigatório.';
          }
          if (msg.contains('valid number') || msg.contains('valid float')) {
            return '$rotulo: informe um número.';
          }
          return '$rotulo: $msg';
        }).join('\n\n');
      }

      if (detalhe is String) {
        // A view embrulha qualquer falha em "Erro ao cadastrar: <exceção crua>",
        // então e-mail repetido chega como violação de unicidade do Postgres.
        if (detalhe.contains('UniqueViolation') ||
            detalhe.contains('duplicate key') ||
            detalhe.contains('already exists')) {
          return 'Este e-mail já está cadastrado.\n\nTente entrar na sua conta ou use outro endereço.';
        }
        return detalhe;
      }
    } catch (_) {
      // Corpo não era JSON; cai na mensagem genérica abaixo.
    }
    return 'Não foi possível concluir o cadastro (erro ${resposta.statusCode}).';
  }

  Future<void> _cadastrarUsuario() async {
    if (_enviando) return;

    final erroLocal = _validarCampos();
    if (erroLocal != null) {
      _mostrarErro(erroLocal);
      return;
    }

    final String apiUrl = '$baseUrl/api/usuarios/';

    Map<String, dynamic> userData = {
      "nm_usuario": _nameController.text.trim(),
      "em_usuario": _emailController.text.trim(),
      "pwd_usuario": _passwordController.text,
      "qtd_dias": _selectedDays,
      "objetivo": _selectedGoal,
      "peso": double.parse(_weightController.text.replaceAll(',', '.')),
      "altura": double.parse(_heightController.text.replaceAll(',', '.')),
      "foco": _selectedFocus,
      "ids_lesoes": _selectedLesoes.toList(),
    };

    setState(() => _enviando = true);
    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(userData),
          )
          // O cadastro espera a IA montar a ficha; o padrão do http é curto
          // demais para isso.
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _mostrarSucesso();
        if (mounted) Navigator.pop(context);
      } else {
        _mostrarErro(_mensagemDeErro(response));
      }
    } on TimeoutException {
      if (mounted) {
        _mostrarErro(
          'O servidor demorou demais para responder.\n\nSeu cadastro pode ter sido criado — tente entrar antes de cadastrar de novo.',
        );
      }
    } catch (e) {
      debugPrint('Erro de conexão: $e');
      if (mounted) {
        _mostrarErro(
          'Não foi possível falar com o servidor.\n\nVerifique sua conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => _ErrorDialog(mensagem: mensagem),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _mostrarSucesso() {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const _SuccessDialog(),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  /// Dropdown com a mesma casca dos campos de texto.
  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
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
  }

  static DropdownMenuItem<T> _item<T>(T value, String texto) =>
      DropdownMenuItem<T>(
        value: value,
        child: Text(
          texto,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Cabeçalho com o botão voltar no lugar da AppBar sólida.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.text),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Voltar',
                    ),
                    const Expanded(
                      child: GradientText(
                        'Criar Conta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GlowDivider(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Conte-nos sobre você',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textDim,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // --- CAMPOS DE TEXTO ---
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600),
                        decoration: neonInput(
                          label: 'Nome Completo',
                          icon: Icons.person_outline_rounded,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600),
                        decoration: neonInput(
                          label: 'E-mail',
                          icon: Icons.mail_outline_rounded,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600),
                        decoration: neonInput(
                          label: 'Senha',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _senhaVisivel
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textDim,
                              size: 21,
                            ),
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        obscureText: !_senhaVisivel,
                      ),
                      const SizedBox(height: 14),

                      // PESO E ALTURA
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600),
                              decoration: neonInput(
                                label: 'Peso (kg)',
                                icon: Icons.monitor_weight_outlined,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600),
                              decoration: neonInput(
                                label: 'Altura (m)',
                                icon: Icons.height_rounded,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // --- SELETORES ---
                      _dropdown<String>(
                        label: 'Objetivo',
                        value: _selectedGoal,
                        items: _goalOptions.entries
                            .map((e) => _item(e.value, e.key))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGoal = v!),
                      ),
                      const SizedBox(height: 14),
                      _dropdown<String>(
                        label: 'Foco do Treino',
                        value: _selectedFocus,
                        items: _focusOptions.entries
                            .map((e) => _item(e.value, e.key))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedFocus = v!),
                      ),
                      const SizedBox(height: 22),

                      // Dias vira chip: a escolha é curta e fica visível de uma vez.
                      const FieldLabel('Dias de treino por semana'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _daysOptions
                            .map((d) => NeonChip(
                                  label: '$d dias',
                                  selected: _selectedDays == d,
                                  fontSize: 13,
                                  onTap: () =>
                                      setState(() => _selectedDays = d),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 26),
                      const FieldLabel('Lesões / Restrições'),
                      const SizedBox(height: 4),
                      const Text(
                        'Selecione caso tenha alguma lesão ou restrição',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.textFaint),
                      ),
                      const SizedBox(height: 10),
                      _buildLesoesPicker(),
                      const SizedBox(height: 36),

                      GradientButton(
                        label: 'FINALIZAR CADASTRO',
                        onPressed: _enviando ? null : _cadastrarUsuario,
                        loading: _enviando,
                        // A espera é longa; sem sinal na tela o usuário toca de
                        // novo ou acha que o app travou.
                        loadingLabel: 'MONTANDO SEU TREINO...',
                        height: 58,
                        fontSize: 17,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Casca dos diálogos: card de vidro escuro com halo colorido.
class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.children,
    required this.glow,
    this.width = 290,
  });

  final List<Widget> children;
  final Color glow;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.stroke, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: glow.withValues(alpha: 0.35),
                blurRadius: 44,
                spreadRadius: -12,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      glow: AppColors.success,
      children: [
        const GlowBadge(
          icon: Icons.check_rounded,
          glowColor: AppColors.success,
          gradient: LinearGradient(
            colors: [AppColors.success, AppColors.cyan],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Cadastro realizado!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Seus treinos foram gerados.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textDim,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorDialog extends StatelessWidget {
  const _ErrorDialog({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      glow: AppColors.danger,
      width: 310,
      children: [
        const GlowBadge(
          icon: Icons.priority_high_rounded,
          glowColor: AppColors.danger,
          gradient: LinearGradient(
            colors: [AppColors.danger, AppColors.magenta],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Não foi possível cadastrar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textDim,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'ENTENDI',
          fontSize: 15,
          height: 48,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
