import 'package:flutter/material.dart';
import './register_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream, // Fundo cor de pergaminho/creme
      body: SafeArea(
        child: SingleChildScrollView( // Evita erro de overflow com o teclado
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Título do App
              Text(
                'Treine Se',
                style: TextStyle(
                  fontSize: 48, 
                  fontWeight: FontWeight.w900,
                  color: inkBrown,
                  letterSpacing: 2,
                  // DICA: Importe uma fonte como 'Chewy' ou 'Bangers' do Google Fonts
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),

              // Imagem do Mascote (Substitua pelo caminho correto da sua imagem gerada)
              // Se ainda não tiver a imagem, isso vai mostrar um ícone temporário
              Container(
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: inkBrown, width: 3),
                ),
                child: ClipOval(
                  // child: Image.asset('assets/images/mascote.png', fit: BoxFit.cover),
                  child: Icon(Icons.fitness_center, size: 80, color: inkBrown),
                ),
              ),

              const SizedBox(height: 40),

              // Campo de E-mail
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'NOME DE USUÁRIO / E-MAIL',
                  labelStyle: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
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

              // Campo de Senha
              TextFormField(
                controller: _passwordController,
                style: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'SENHA',
                  labelStyle: TextStyle(color: inkBrown, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
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

              // Botão Entrar Vintage
              ElevatedButton(
                onPressed: () {
                  print('Login: ${_emailController.text}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: vintageRed,
                  foregroundColor: bgCream, // Cor do texto
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 6, // Dá uma sombra legal
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: inkBrown, width: 3), // Borda grossa de desenho
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

              // Botão de Cadastro
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