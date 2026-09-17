import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class MainScaffold extends StatefulWidget {
  final int idUsuario;
  final String nomeUsuario;

  const MainScaffold({
    super.key,
    required this.idUsuario,
    required this.nomeUsuario,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(idUsuario: widget.idUsuario, nomeUsuario: widget.nomeUsuario),
      ProfileScreen(
          idUsuario: widget.idUsuario, nomeUsuario: widget.nomeUsuario),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // O fundo fica no scaffold, e não em cada tela: assim os halos não
      // "pulam" ao trocar de aba.
      body: NeonBackground(child: _pages[_currentIndex]),
      bottomNavigationBar: _NeonNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Barra flutuante de vidro. O item ativo vira uma pílula com o gradiente da
/// marca, o inativo fica só com o ícone apagado.
class _NeonNavBar extends StatelessWidget {
  const _NeonNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _itens = [
    (icon: Icons.fitness_center_rounded, label: 'Treinos'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.bgElevated.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.stroke, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.18),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Row(
            children: List.generate(_itens.length, (i) {
              final ativo = i == currentIndex;
              final item = _itens[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: ativo ? AppColors.brand : null,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: ativo
                          ? [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.45),
                                blurRadius: 18,
                                spreadRadius: -4,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: ativo ? Colors.white : AppColors.textFaint,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: ativo ? Colors.white : AppColors.textFaint,
                            fontWeight:
                                ativo ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
