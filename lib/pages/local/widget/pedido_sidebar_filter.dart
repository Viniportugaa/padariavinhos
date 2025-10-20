import 'package:flutter/material.dart';

class PedidoSidebarFilter extends StatelessWidget {
  final String? filtroSelecionado;
  final Function(String?) onFiltroChanged;

  const PedidoSidebarFilter({
    super.key,
    required this.filtroSelecionado,
    required this.onFiltroChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtros = ['Todos', 'pendente', 'em preparo', 'pronto', 'entregue'];

    return Container(
      color: Colors.brown[50],
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📦 Filtrar Pedidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 12),
          ...filtros.map((filtro) {
            final selecionado = filtroSelecionado == filtro;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onFiltroChanged(filtro == 'Todos' ? null : filtro),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? Colors.brown[300]
                        : Colors.brown.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selecionado
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                        selecionado ? Colors.white : Colors.brown.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        filtro == 'Todos'
                            ? 'Todos os pedidos'
                            : filtro[0].toUpperCase() + filtro.substring(1),
                        style: TextStyle(
                          color: selecionado ? Colors.white : Colors.brown[700],
                          fontWeight:
                          selecionado ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const Spacer(),
          const Divider(),
          Center(
            child: Text(
              "Painel Local v2.0",
              style: TextStyle(
                fontSize: 12,
                color: Colors.brown[300],
              ),
            ),
          )
        ],
      ),
    );
  }
}
