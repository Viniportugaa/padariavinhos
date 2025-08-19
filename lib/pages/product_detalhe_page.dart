import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String produtoId;

  const ProductDetailPage({super.key, required this.produtoId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController _observacaoController = TextEditingController();
  final List<Acompanhamento> _selecionados = [];

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produtos = context
        .watch<ProductsNotifier>()
        .produtos;
    final Produto produto = produtos.firstWhere(
          (p) => p.id == widget.produtoId,
      orElse: () => throw Exception('Produto não encontrado'),
    );

    return Scaffold(
      appBar: AppBar(title: Text(produto.nome)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: produto.id,
              child: produto.imageUrl.isNotEmpty
                  ? Image.network(
                produto.imageUrl.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              )
                  : const Icon(
                  Icons.broken_image, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(produto.nome,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(produto.descricao, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('R\$ ${produto.preco.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const SizedBox(height: 24),

            // Campo de observação
            TextField(
              controller: _observacaoController,
              decoration: const InputDecoration(
                labelText: 'Observação',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de acompanhamentos
            if (produto.acompanhamentosDisponiveis.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Escolha até 3 acompanhamentos:',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: produto.acompanhamentosDisponiveis.map((acomp) {
                      final isSelected = _selecionados.contains(acomp);
                      return ChoiceChip(
                        label: Text(acomp.nome),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (_selecionados.length < 3) {
                                _selecionados.add(acomp);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Você só pode escolher até 3 acompanhamentos'),
                                  ),
                                );
                              }
                            } else {
                              _selecionados.remove(acomp);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            ElevatedButton.icon(
              onPressed: () {
                _adicionarAoCarrinho(context, produto);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Adicionar ao carrinho'),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarAoCarrinho(BuildContext context, Produto produto) {
    context.read<CarrinhoProvider>().adicionarProduto(
      produto,
      1,
      observacao: _observacaoController.text.isNotEmpty
          ? _observacaoController.text
          : null,
      acompanhamentos: _selecionados.isNotEmpty ? _selecionados : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produto adicionado ao carrinho!')),
    );
    Navigator.pop(context);
  }
}
