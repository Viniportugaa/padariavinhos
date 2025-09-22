import 'package:flutter/material.dart';

class TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool destaque;

  const TotalRow({
    super.key,
    required this.label,
    required this.value,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: destaque ? 18 : 16,
              fontWeight: destaque ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            "R\$ ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: destaque ? 18 : 16,
              fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
              color: destaque ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
