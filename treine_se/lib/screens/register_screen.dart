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
  final Color bgCream = const Color(0xFFF5E6BE);
  final Color inkBrown = const Color(0xFF3D2B1F);
  final Color vintageRed = const Color(0xFFBC4749);

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

  Future<void> _cadastrarUsuario() async {
    final String apiUrl = '$baseUrl/api/usuarios/';

    Map<String, dynamic> userData = {
      "nm_usuario": _nameController.text,
      "em_usuario": _emailController.text,
      "pwd_usuario": _passwordController.text,
      "qtd_dias": _selectedDays,
      "objetivo": _selectedGoal,
      "peso": double.tryParse(_weightController.text) ?? 0.0,
      "altura": double.tryParse(_heightController.text) ?? 0.0,
      "foco": _selectedFocus,
      "ids_lesoes": _selectedLesoes.toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          await _mostrarSucesso();
          if (mounted) Navigator.pop(context);
        } else {
          debugPrint("Erro: ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
    }
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
              onPressed: _cadastrarUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: vintageRed,
                foregroundColor: bgCream,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: inkBrown, width: 3), // Borda estilo desenho
                ),
              ),
              child: const Text(
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
            color: const Color(0xFFF5E6BE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3D2B1F), width: 3),
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
                  color: Color(0xFF3D2B1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seus treinos foram gerados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF3D2B1F).withValues(alpha: 0.7),
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