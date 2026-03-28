import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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
  String _selectedGoal = "Ganho de força";
  String _selectedFocus = "Equilibrado";
  int _selectedDays = 4;

  // Listas de opções para os seletores
  final List<String> _goalOptions = ["Ganho de força", "Definição", "Perder Gordura"];
  final List<String> _focusOptions = ["Superiores", "Inferiores", "Abdomen", "Equilibrado"];
  final List<int> _daysOptions = [2, 3, 4, 5];

  // --- Paleta de Cores Vintage ---
  final Color bgCream = const Color(0xFFF5E6BE);
  final Color inkBrown = const Color(0xFF3D2B1F);
  final Color vintageRed = const Color(0xFFBC4749);

  Future<void> _cadastrarUsuario() async {
    final String apiUrl = "http://192.168.1.106:8000/api/usuarios/";

    Map<String, dynamic> userData = {
      "nm_usuario": _nameController.text,
      "em_usuario": _emailController.text,
      "pwd_usuario": _passwordController.text,
      "qtd_dias": _selectedDays,
      "objetivo": _selectedGoal,
      "peso": double.tryParse(_weightController.text) ?? 0.0,
      "altura": double.tryParse(_heightController.text) ?? 0.0,
      "foco": _selectedFocus,
      "ids_lesoes": [] 
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastrado com sucesso!')),
          );
          Navigator.pop(context);
        } else {
          print("Erro: ${response.body}");
        }
      }
    } catch (e) {
      print("Erro de conexão: $e");
    }
  }

  // --- HELPER: Função para não repetir o estilo das bordas em todos os campos ---
  InputDecoration _buildVintageDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
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
      backgroundColor: bgCream, // Fundo temático
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0, // Tira a sombra padrão
        iconTheme: IconThemeData(color: inkBrown, size: 28), // Ícone de voltar escuro
        title: Text(
          'Criar Conta', 
          style: TextStyle(color: inkBrown, fontWeight: FontWeight.w900, fontSize: 26)
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: Container(color: inkBrown, height: 3.0), // Linha de divisão estilo quadrinho
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
              dropdownColor: bgCream, // Fundo da lista ao abrir
              iconEnabledColor: inkBrown,
              items: _goalOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
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
              items: _focusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold)),
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