import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

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

  // --- Paleta de Cores Vintage ---
  final Color bgCream = const Color(0xFFEDF2F7);
  final Color inkBrown = const Color(0xFF2D4F6B);
  final Color vintageRed = const Color(0xFF7B9EC5);

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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(color: vintageRed, strokeWidth: 2)),
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
        return FilterChip(
          label: Text(
            nome,
            style: TextStyle(
              color: selected ? bgCream : inkBrown,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          selected: selected,
          onSelected: (val) => setState(() {
            if (id == nenhumaId) {
              _selectedLesoes.clear();
              if (val) { _selectedLesoes.add(id); }
            } else {
              _selectedLesoes.remove(nenhumaId);
              if (val) { _selectedLesoes.add(id); }
              else { _selectedLesoes.remove(id); }
            }
          }),
          selectedColor: vintageRed,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          side: BorderSide(
            color: selected ? inkBrown : inkBrown.withValues(alpha: 0.3),
            width: 1.5,
          ),
          checkmarkColor: bgCream,
          showCheckmark: false,
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
      barrierColor: Colors.black54,
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
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const _SuccessDialog(),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // --- HELPER: Função para não repetir o estilo das bordas em todos os campos ---
  InputDecoration _buildVintageDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.5),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inkBrown, width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inkBrown, width: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0, 
        iconTheme: IconThemeData(color: inkBrown, size: 28), 
        title: Text(
          'Criar Conta', 
          style: TextStyle(color: inkBrown, fontWeight: FontWeight.w900, fontSize: 26)
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: inkBrown, height: 3.0), 
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Conte-nos sobre você',
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.w900,
                color: inkBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // --- CAMPOS DE TEXTO ---
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
              decoration: _buildVintageDecoration('Nome Completo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
              decoration: _buildVintageDecoration('E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
              decoration: _buildVintageDecoration('Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            // PESO E ALTURA
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                    decoration: _buildVintageDecoration('Peso (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                    decoration: _buildVintageDecoration('Altura (m)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- SELETORES (DROPDOWNS) ---
            
            // 1. Seletor de Objetivo
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              decoration: _buildVintageDecoration('Objetivo'),
              dropdownColor: bgCream,
              iconEnabledColor: inkBrown,
              items: _goalOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key, style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGoal = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // 2. Seletor de Foco
            DropdownButtonFormField<String>(
              value: _selectedFocus,
              decoration: _buildVintageDecoration('Foco do Treino'),
              dropdownColor: bgCream,
              iconEnabledColor: inkBrown,
              items: _focusOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key, style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedFocus = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // 3. Seletor de Dias de Treino
            DropdownButtonFormField<int>(
              value: _selectedDays,
              decoration: _buildVintageDecoration('Dias de treino por semana'),
              dropdownColor: bgCream,
              iconEnabledColor: inkBrown,
              items: _daysOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value dias', style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedDays = newValue!;
                });
              },
            ),

            const SizedBox(height: 24),
            Text(
              'Lesões / Restrições',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: inkBrown),
            ),
            Text(
              'Selecione caso tenha alguma lesão ou restrição',
              style: TextStyle(fontSize: 11, color: inkBrown.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            _buildLesoesPicker(),
            const SizedBox(height: 40),

            // --- BOTÃO DE CADASTRO VINTAGE ---
            ElevatedButton(
              onPressed: _enviando ? null : _cadastrarUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: vintageRed,
                foregroundColor: bgCream,
                disabledBackgroundColor: vintageRed.withValues(alpha: 0.6),
                disabledForegroundColor: bgCream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: inkBrown, width: 3), // Borda estilo desenho
                ),
              ),
              child: _enviando
                  // A espera é longa; sem sinal na tela o usuário toca de novo
                  // ou acha que o app travou.
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(bgCream),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'MONTANDO SEU TREINO...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'FINALIZAR CADASTRO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
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
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2D4F6B), width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(4, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cadastro realizado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D4F6B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seus treinos foram gerados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF2D4F6B).withValues(alpha: 0.7),
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


class _ErrorDialog extends StatelessWidget {
  const _ErrorDialog({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    const inkBrown = Color(0xFF2D4F6B);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: inkBrown, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(4, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFC0563F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Não foi possível cadastrar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: inkBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: inkBrown.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inkBrown,
                    foregroundColor: const Color(0xFFEDF2F7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'ENTENDI',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
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
