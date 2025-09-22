import 'package:flutter/material.dart';

class PedidoStatusChip extends StatelessWidget {
  final String status;

  const PedidoStatusChip({super.key, required this.status});

  Color _statusColor() {
    switch (status) {
      case 'pendente':
        return Colors.amber;
      case 'em preparo':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: _statusColor(),
    );
  }
}
