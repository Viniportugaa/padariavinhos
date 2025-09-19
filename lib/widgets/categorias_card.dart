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
    final bgColor = selecionado ? Colors.orange : _getColorForCategoria(nome);
    final iconColor = selecionado ? Colors.white : Colors.black;
    final textColor = selecionado ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(  // ← aqui precisa do `child`
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minWidth: 80),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 3),
            Text(nome, style: TextStyle(fontSize: 10, color: textColor)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward_ios, size: 12, color: iconColor),
          ],
        ),
      ),
    );
  }

  Color _getColorForCategoria(String nome) {
    switch (nome.toLowerCase()) {
      case 'favoritos': return Colors.pink[500]!;
      default: return Colors.orange;
    }
  }
}