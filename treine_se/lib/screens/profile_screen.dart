import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String nomeUsuario;

  const ProfileScreen({super.key, required this.nomeUsuario});

  static const Color bgCream  = Color(0xFFF5E6BE);
  static const Color inkBrown = Color(0xFF3D2B1F);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: bgCream,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: inkBrown,
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 3, color: inkBrown),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Em breve...',
                style: TextStyle(color: inkBrown, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
