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
        constraints: const BoxConstraints(minWidth: 80),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15),
            const SizedBox(height: 3),
            Text(nome, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_ios, size: 12),
          ],
        ),
      ),
    );
  }
}