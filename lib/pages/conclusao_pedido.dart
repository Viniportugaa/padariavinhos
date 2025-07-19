import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pedido_service.dart';
import '../services/carrinhos_provider.dart';
import 'package:go_router/go_router.dart';

class ConclusaoPedidoPage extends StatefulWidget {
  @override
  State<ConclusaoPedidoPage> createState() => _ConclusaoPedidoPageState();
}

class _ConclusaoPedidoPageState extends State<ConclusaoPedidoPage> {
  bool _isLoading = false;

  Future<void> _finalizarPedido() async {
    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

    if (carrinho.itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seu carrinho está vazio!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PedidoService().criarPedido(
        carrinho.itens.values.toList(),
        total: carrinho.total,
      );
      carrinho.limpar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido finalizado com sucesso!')),
      );
      Navigator.of(context).pop(); // volta para página anterior (ex: fazer pedido)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar pedido: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = Provider.of<CarrinhoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: Colors.red,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: carrinho.itens.isEmpty
              ? const Center(child: Text('Seu carrinho está vazio.'))
              : Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/pedido');
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Voltar'),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: carrinho.itens.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = carrinho.itens.values.elementAt(index);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.produto.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      carrinho.diminuirQuantidade(item.produto.id);
                                    },
                                  ),
                                  Text('${item.quantidade}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      carrinho.aumentarQuantidade(item.produto.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      carrinho.remover(item.produto.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Text(
                          'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );

                    // return ListTile(
                    //   title: Text(item.produto.nome,
                    //       style: const TextStyle(fontWeight: FontWeight.bold)),
                    //   subtitle: Text('Quantidade: ${item.quantidade}'),
                    //   trailing: Text(
                    //     'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2)}',
                    //     style: const TextStyle(color: Colors.green),
                    //   ),
                    // );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('R\$ ${carrinho.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _finalizarPedido,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Finalizar Pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
