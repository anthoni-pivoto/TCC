import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

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

  static const Color inkBrown = Color(0xFF2D4F6B);
  static const Color bgCream  = Color(0xFFEDF2F7);
  static const Color vintageRed = Color(0xFF7B9EC5);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(idUsuario: widget.idUsuario, nomeUsuario: widget.nomeUsuario),
      ProfileScreen(idUsuario: widget.idUsuario, nomeUsuario: widget.nomeUsuario),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: inkBrown, width: 2.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: bgCream,
          selectedItemColor: vintageRed,
          unselectedItemColor: inkBrown,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Treinos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
