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
  // Inicializamos com o primeiro valor de cada lista para não dar erro
  String _selectedGoal = "Ganho de força";
  String _selectedFocus = "Equilibrado";
  int _selectedDays = 4;

  // Listas de opções para os seletores
  final List<String> _goalOptions = ["Ganho de força", "Definição", "Perder Gordura"];
  final List<String> _focusOptions = ["Superiores", "Inferiores", "Abdomen", "Equilibrado"];
  final List<int> _daysOptions = [2, 3, 4, 5];

  Future<void> _cadastrarUsuario() async {
    final String apiUrl = "http://192.168.0.234:8000/api/usuarios/";

    Map<String, dynamic> userData = {
      "nm_usuario": _nameController.text,
      "em_usuario": _emailController.text,
      "pwd_usuario": _passwordController.text,
      "qtd_dias": _selectedDays, // Pegando o valor do seletor
      "objetivo": _selectedGoal, // Pegando o valor do seletor
      "peso": double.tryParse(_weightController.text) ?? 0.0,
      "altura": double.tryParse(_heightController.text) ?? 0.0,
      "foco": _selectedFocus,    // Pegando o valor do seletor
      "ids_lesoes": [] // Por enquanto vazio até criarmos a seleção
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Conte-nos sobre você',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // --- CAMPOS DE TEXTO PADRÃO ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            // PESO E ALTURA
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(labelText: 'Altura (m)', border: OutlineInputBorder()),
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
              decoration: const InputDecoration(labelText: 'Objetivo', border: OutlineInputBorder()),
              items: _goalOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
              decoration: const InputDecoration(labelText: 'Foco do Treino', border: OutlineInputBorder()),
              items: _focusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
              decoration: const InputDecoration(labelText: 'Dias de treino por semana', border: OutlineInputBorder()),
              items: _daysOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value dias'),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedDays = newValue!;
                });
              },
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cadastrarUsuario,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Finalizar Cadastro'),
            ),
          ],
        ),
      ),
    );
  }
}