import 'package:flutter/material.dart';

class MotivoCancelamentoDialog extends StatefulWidget {
  final void Function(String motivo) onConfirmar;

  const MotivoCancelamentoDialog({super.key, required this.onConfirmar});

  @override
  State<MotivoCancelamentoDialog> createState() => _MotivoCancelamentoDialogState();
}

class _MotivoCancelamentoDialogState extends State<MotivoCancelamentoDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Cancelar Pedido',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Informe o motivo do cancelamento:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ex: Cliente não respondeu ao WhatsApp...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          icon: _loading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.check),
          label: Text(_loading ? 'Salvando...' : 'Confirmar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: _loading
              ? null
              : () async {
            final motivo = _controller.text.trim();
            if (motivo.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, informe o motivo.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            setState(() => _loading = true);
            await Future.delayed(const Duration(milliseconds: 300)); // animação leve
            widget.onConfirmar(motivo);
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
