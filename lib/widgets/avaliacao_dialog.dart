import 'package:flutter/material.dart';
import 'package:padariavinhos/models/avaliacao_pedido.dart';
import 'package:padariavinhos/services/avaliacao_service.dart';
import 'package:padariavinhos/widgets/rating_stars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';

class AvaliacaoDialog extends StatefulWidget {
  final String pedidoId;

  const AvaliacaoDialog({super.key, required this.pedidoId});

  @override
  State<AvaliacaoDialog> createState() => _AvaliacaoDialogState();
}

class _AvaliacaoDialogState extends State<AvaliacaoDialog> {
  int _nota = 5;
  final TextEditingController _controller = TextEditingController();
  final AvaliacaoService _service = AvaliacaoService();
  bool _loading = false;

  Future<void> _enviar() async {
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final userId = auth.user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário não autenticado.')));
      return;
    }

    setState(() => _loading = true);

    final avaliacao = AvaliacaoPedido(
      pedidoId: widget.pedidoId,
      userId: userId,
      nota: _nota,
      comentario: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
      dataAvaliacao: DateTime.now(),
    );

    try {
      await _service.salvarAvaliacao(avaliacao);
      await _service.marcarPedidoAvaliado(widget.pedidoId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obrigado pela avaliação!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar avaliação: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avaliar pedido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Como foi sua experiência?'),
          const SizedBox(height: 12),
          RatingStars(
            initialRating: _nota,
            onChanged: (r) => _nota = r,
            iconSize: 36,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Deixe um comentário (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _enviar,
          child: _loading ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Text('Enviar'),
        ),
      ],
    );
  }
}
