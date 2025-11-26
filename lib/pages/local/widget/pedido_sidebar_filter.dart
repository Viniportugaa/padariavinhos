import 'package:flutter/material.dart';

class PedidoSidebarFilter extends StatelessWidget {
  final String? filtroStatus;
  final bool filtroHoje;
  final Function(String?) onStatusChange;
  final Function(bool) onHojeChange;

  const PedidoSidebarFilter({
    super.key,
    required this.filtroStatus,
    required this.filtroHoje,
    required this.onStatusChange,
    required this.onHojeChange,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'pendente',
      'em preparo',
      'pronto',
      'entregue',
      'fechado'
    ];

    return Container(
      color: Colors.brown.shade100,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filtros",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),

          // FILTRO HOJE
          SwitchListTile(
            title: const Text(
              "Exibir apenas HOJE",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: filtroHoje,
            onChanged: onHojeChange,
          ),

          const SizedBox(height: 14),
          const Text(
            "Status do Pedido",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          // LISTA DE STATUS
          ...statuses.map((s) {
            final ativo = filtroStatus == s;
            return GestureDetector(
              onTap: () => onStatusChange(ativo ? null : s),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ativo ? Colors.brown.shade300 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ativo ? Colors.brown : Colors.brown.shade200,
                  ),
                ),
                child: Text(
                  s.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ativo ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          const Text(
            "Painel do Balcão",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          )
        ],
      ),
    );
  }
}
