import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';

class EditarObservacaoDialog {
  static void show(BuildContext context, String produtoId, String? observacaoAtual) {
    final controller = TextEditingController(text: observacaoAtual ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Observação'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex: Sem cebola, ponto da carne...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
              final index = carrinho.itens.indexWhere((item) => item.produto.id == produtoId);
              if (index >= 0) {
                carrinho.atualizarObservacao(index, controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
