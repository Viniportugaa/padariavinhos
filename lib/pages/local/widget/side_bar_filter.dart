import 'package:flutter/material.dart';

class SidebarFilter extends StatelessWidget {
  final List<String> categorias;
  final String? selectedCategoria;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String> onSearchChanged;

  const SidebarFilter({
    super.key,
    required this.categorias,
    required this.selectedCategoria,
    required this.onCategoriaChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Adiciona "Todos" no topo da lista
    final categoriasComTodos = ['Todos', ...categorias];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.brown[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buscar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Nome do produto',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 24),
          const Text(
            'Categorias',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: categoriasComTodos.length,
              itemBuilder: (context, index) {
                final categoria = categoriasComTodos[index];
                final isSelected = (categoria == 'Todos' && selectedCategoria == null) ||
                    (categoria != 'Todos' && categoria == selectedCategoria);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: () => onCategoriaChanged(
                        categoria == 'Todos' ? null : categoria),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.brown[300] : Colors.brown[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        categoria,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.brown[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
