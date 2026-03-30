import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import './register_screen.dart';

// --- TELA TEMPORÁRIA (Para onde vamos após o login) ---
class HomeScreen extends StatelessWidget {
  final String nomeUsuario;
  const HomeScreen({super.key, required this.nomeUsuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treine Se - Início')),
      body: Center(
        child: Text(
          'Bem-vindo(a), $nomeUsuario! Você está logado(a).',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- Paleta de Cores Vintage ---
  final Color bgCream = const Color(0xFFF5E6BE);
  final Color inkBrown = const Color(0xFF3D2B1F);
  final Color vintageRed = const Color(0xFFBC4749);
  final Color vintageBlue = const Color(0xFF457B9D);

  // --- Função de Login ---
  Future<void> _efetuarLogin() async {
    final String apiUrl = "http://192.168.1.106:8000/api/usuarios/login";

    Map<String, dynamic> loginData = {
      "em_usuario": _emailController.text.trim(),
      "pwd_usuario": _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginData),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final usuarioLogado = jsonDecode(response.body);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login efetuado com sucesso!'), backgroundColor: Colors.green),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(nomeUsuario: usuarioLogado['nm_usuario']),
            ),
          );

        } else if (response.statusCode == 401) {
          // Unauthorized (Senha ou e-mail errados)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-mail ou senha incorretos!'), backgroundColor: Colors.red),
          );
        } else {
          print("Erro: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro no servidor. Tente novamente mais tarde.')),
          );
        }
      }
    } catch (e) {
      print("Erro de conexão: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de rede. Verifique sua conexão.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              Text(
                'Treine Se',
                style: TextStyle(
                  fontSize: 48, 
                  fontWeight: FontWeight.w900,
                  color: inkBrown,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: inkBrown, width: 3),
                ),
                child: ClipOval(
                  child: Icon(Icons.fitness_center, size: 80, color: inkBrown),
                ),
              ),

              const SizedBox(height: 40),

              TextFormField(
                controller: _emailController,
                style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'E-MAIL',
                  labelStyle: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                  filled: true,
                  prefixIcon: Icon(Icons.email_outlined, color: inkBrown),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inkBrown, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inkBrown, width: 4),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'SENHA',
                  labelStyle: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                  filled: true,
                  prefixIcon: Icon(Icons.lock_outline, color: inkBrown),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inkBrown, width: 2.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inkBrown, width: 4),
                  ),
                ),
                obscureText: true, 
              ),
              
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _efetuarLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vintageRed,
                  foregroundColor: bgCream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: inkBrown, width: 3),
                  ),
                ),
                child: const Text(
                  'ENTRAR',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: vintageBlue,
                ),
                child: const Text(
                  'Criar uma conta? Cadastre-se',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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