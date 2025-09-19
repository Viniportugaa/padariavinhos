import 'package:flutter/material.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import '../dialogs/editar_observacao_dialog.dart';
import '../dialogs/editar_acompanhamentos_dialog.dart';
import '../controller/conclusao_pedido_controller.dart';
import 'glass_card.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';

class CarrinhoItemCard extends StatelessWidget {
  final ItemCarrinho item;
  final int index;
  final CarrinhoProvider carrinho;
  final ConclusaoPedidoController controller;

  const CarrinhoItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.carrinho,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Imagem do produto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    item.produto.imageUrl.isNotEmpty
                        ? item.produto.imageUrl.first
                        : 'assets/imagem_padrao.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                ),
                const SizedBox(width: 12),
                // Detalhes do produto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.produto.nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Qtd: ${item.quantidade}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if ((item.observacao ?? '').isNotEmpty)
                        Text(
                          'Obs: ${item.observacao}',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 14),
                        ),
                      if ((item.acompanhamentos ?? []).isNotEmpty)
                        Text(
                          'Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                // Preço e ações
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (context) {
                        final precoUnitario = PrecoHelper.calcularPrecoUnitario(
                          produto: item.produto,
                          selecionados: item.acompanhamentos ?? [],
                        );
                        final total = precoUnitario * item.quantidade;
                        return Text(
                          'R\$ ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => carrinho.diminuirQuantidade(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => carrinho.aumentarQuantidade(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => carrinho.removerPorIndice(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Botões de edição
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => EditarObservacaoDialog.show(
                      context, item.produto.id, item.observacao),
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Editar Obs'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => EditarAcompanhamentosDialog.show(
                      context, index, item, controller),
                  icon: const Icon(Icons.fastfood),
                  label: const Text('Editar Acomp.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
