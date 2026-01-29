import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SidebarFilter extends StatelessWidget {
  final List<String> categorias;
  final String? selectedCategoria;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAbrirChamadasGarcom;

  const SidebarFilter({
    super.key,
    required this.categorias,
    required this.selectedCategoria,
    required this.onCategoriaChanged,
    required this.onSearchChanged,
    required this.onAbrirChamadasGarcom,
  });

  @override
  Widget build(BuildContext context) {
    final categoriasComTodos = ['Todos', ...categorias];

    return Container(
      width: 240,
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
          // ---------------- BUSCA ----------------
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

          // ---------------- CATEGORIAS ----------------
          const Text(
            'Categorias',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              children: [
                ...categoriasComTodos.map((categoria) {
                  final isSelected = (categoria == 'Todos' && selectedCategoria == null)
                      || (categoria != 'Todos' && categoria == selectedCategoria);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: GestureDetector(
                      onTap: () => onCategoriaChanged(
                          categoria == 'Todos' ? null : categoria),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.brown[300]
                              : Colors.brown[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoria,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.brown[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 30),

                // ---------------- CHAMADAS GARÇOM ----------------
                const Text(
                  "Chamadas de Garçom",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("notificacoes_garcom")
                      .where("lido", isEqualTo: false)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text("Nenhuma mesa chamando."),
                      );
                    }

                    return Column(
                      children: docs.map((d) {
                        final mesa = d['mesa'];

                        return GestureDetector(
                          onTap: onAbrirChamadasGarcom,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active,
                                    color: Colors.brown),
                                const SizedBox(width: 10),
                                Text(
                                  "Mesa $mesa",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
