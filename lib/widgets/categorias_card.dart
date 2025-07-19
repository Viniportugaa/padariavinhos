import 'package:flutter/material.dart';

class CategoriaCard extends StatelessWidget {
  final IconData icon;
  final String nome;
  final VoidCallback onTap;
  final bool selecionado;


  const CategoriaCard({
    required this.icon,
    required this.nome,
    required this.onTap,
    super.key,
    this.selecionado = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 4),
            Text(nome, style: const TextStyle(fontSize: 12)),
            const Icon(Icons.arrow_forward_ios, size: 12),
          ],
        ),
      ),
    );
  }
}