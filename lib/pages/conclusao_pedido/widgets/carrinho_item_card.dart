import 'package:flutter/material.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import '../dialogs/editar_observacao_dialog.dart';
import '../dialogs/editar_acompanhamentos_dialog.dart';
import '../controller/conclusao_pedido_controller.dart';
import 'glass_card.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

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

  /// Retorna o valor cobrado do acompanhamento individual seguindo a regra proposta
  double precoAcompanhamentoCobrado(
      Acompanhamento a, List<Acompanhamento> selecionados, Produto produto) {
    if (produto.category.toLowerCase() != 'pratos') {
      return a.preco; // sempre cobra
    }

    if (selecionados.length <= 3) return 0.0; // até 3 grátis

    // Quantidade de acompanhamentos que devem ser cobrados
    final numeroACobrar = selecionados.length - 3;

    // Ordena todos os preços do menor para o maior
    final precosOrdenados = selecionados.map((e) => e.preco).toList()..sort();

    // Pega os menores valores correspondentes ao número a cobrar
    final valoresACobrar = precosOrdenados.take(numeroACobrar).toList();

    // Se o preço do acompanhamento 'a' estiver entre os valores a cobrar, retorna seu preço
    if (valoresACobrar.contains(a.preco)) {
      return a.preco;
    }

    return 0.0; // grátis se não estiver entre os cobrados
  }

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Acompanhamentos:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            ...item.acompanhamentos!.map((a) {
                              final preco = precoAcompanhamentoCobrado(
                                  a, item.acompanhamentos!, item.produto);
                              return Text(
                                '${a.nome} ${preco > 0 ? '+R\$${preco.toStringAsFixed(2)}' : '(GRÁTIS)'}',
                                style: const TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic),
                              );
                            }).toList(),
                          ],
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