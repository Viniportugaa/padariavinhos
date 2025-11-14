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
    final opcoes = [
      {'label': 'Todos os pedidos', 'valor': null},
      {'label': 'Pendente', 'valor': 'pendente'},
      {'label': 'Em preparo', 'valor': 'em preparo'},
      {'label': 'Pronto', 'valor': 'pronto'},
      {'label': 'Entregue', 'valor': 'entregue'},
      {'label': 'Fechado', 'valor': 'fechado'},
    ];

    return Container(
      color: Colors.brown.shade100,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filtrar Pedidos",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 10),
          ...opcoes.map((op) {
            final selecionado = filtroSelecionado == op['valor'];
            return ListTile(
              dense: true,
              title: Text(op['label']!),
              leading: Radio<String?>(
                value: op['valor'],
                groupValue: filtroSelecionado,
                onChanged: (valor) => onFiltroChanged(valor),
              ),
              selected: selecionado,
              selectedColor: Colors.brown.shade700,
            );
          }),
        ],
      ),
    );
  }
}
