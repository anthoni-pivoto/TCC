import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import './register_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/ui.dart';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _senhaVisivel = false;
  bool _entrando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Função de Login ---
  Future<void> _efetuarLogin() async {
    if (_entrando) return;

    final String apiUrl = '$baseUrl/api/usuarios/login';

    Map<String, dynamic> loginData = {
      "em_usuario": _emailController.text.trim(),
      "pwd_usuario": _passwordController.text,
    };

    setState(() => _entrando = true);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginData),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final usuarioLogado = jsonDecode(response.body);

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => MainScaffold(
                idUsuario: usuarioLogado['id_usuario'],
                nomeUsuario: usuarioLogado['nm_usuario'],
              ),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
            ),
          );
        } else if (response.statusCode == 401) {
          // Unauthorized (Senha ou e-mail errados)
          _aviso('E-mail ou senha incorretos!', AppColors.danger);
        } else {
          debugPrint("Erro: ${response.body}");
          _aviso('Erro no servidor. Tente novamente mais tarde.',
              AppColors.danger);
        }
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
      if (mounted) {
        _aviso('Erro de rede. Verifique sua conexão.', AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  void _aviso(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.bgElevated,
        showCloseIcon: true,
        closeIconColor: AppColors.textDim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: cor.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // --- Marca ---
                const GradientText(
                  'Treine Se',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Expanded(child: GlowDivider()),
                    SizedBox(width: 12),
                    Text(
                      'Seu treino. Seu ritmo.',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: GlowDivider()),
                  ],
                ),

                const SizedBox(height: 28),
                const Center(child: OrbitLogo(size: 200)),
                const SizedBox(height: 36),

                // --- Campos ---
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: neonInput(
                    label: 'E-MAIL',
                    icon: Icons.mail_outline_rounded,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: neonInput(
                    label: 'SENHA',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _senhaVisivel
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textDim,
                        size: 21,
                      ),
                      tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  obscureText: !_senhaVisivel,
                  onFieldSubmitted: (_) => _efetuarLogin(),
                ),

                const SizedBox(height: 30),

                GradientButton(
                  label: 'ENTRAR',
                  onPressed: _efetuarLogin,
                  loading: _entrando,
                  height: 58,
                  fontSize: 20,
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Criar uma conta?',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 350),
                            pageBuilder: (_, __, ___) => const RegisterScreen(),
                            transitionsBuilder: (_, animation, __, child) =>
                                SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const GradientText(
                        'Cadastre-se',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
