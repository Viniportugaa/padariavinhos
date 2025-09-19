import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/pages/fazer_pedido/add_to_cart_sheet.dart';

void showProdutoDetalhesSheet(
    BuildContext context,
    Produto produto, {
      List<Acompanhamento>? acompanhamentos,
    }) {
  final List<Acompanhamento> _acompanhamentos = acompanhamentos ?? [];

  // Filtra apenas os acompanhamentos que pertencem ao produto
  final acompanhamentosDoProduto = _acompanhamentos
      .where((a) => produto.acompanhamentosIds.contains(a.id))
      .toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 32,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagem com gradiente
                if (produto.imageUrl != null && produto.imageUrl!.isNotEmpty)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Image.network(
                          produto.imageUrl!.first,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 220,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Text(
                          produto.nome,
                          style: const TextStyle(
                            fontFamily: 'Pacifico',
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                // Conteúdo do modal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preço
                      Text(
                        'R\$ ${produto.preco.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Descrição
                      if (produto.descricao != null && produto.descricao!.isNotEmpty)
                        Text(produto.descricao!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),

                      // Acompanhamentos
                      if (acompanhamentosDoProduto.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acompanhamentos disponíveis:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: acompanhamentosDoProduto.map((a) {
                                final label = a.preco > 0
                                    ? '${a.nome} (+R\$ ${a.preco.toStringAsFixed(2)})'
                                    : a.nome;

                                return Chip(
                                  label: Text(label),
                                  backgroundColor: Colors.deepOrange,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Botão Adicionar ao Carrinho
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Chama o AddToCartSheet com os acompanhamentos do produto
                          showAddToCartSheet(context, produto, acompanhamentosDoProduto);
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Adicionar ao Carrinho'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}