import 'package:flutter/material.dart';

class ProdutoSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const ProdutoSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 45, // altura menor
        decoration: BoxDecoration(
          color: Colors.grey[200], // fundo suave
          borderRadius: BorderRadius.circular(12), // borda arredondada
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2), // sombra sutil
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Buscar produto',
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            border: InputBorder.none, // remove a borda padrão
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}
