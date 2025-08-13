import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/services/pedido_service.dart';


class ConclusaoPedidoPage extends StatefulWidget {
  @override
  State<ConclusaoPedidoPage> createState() => _ConclusaoPedidoPageState();
}

class _ConclusaoPedidoPageState extends State<ConclusaoPedidoPage> {
  bool _isLoading = false;

  void _finalizarPedido() async{
    if (_isLoading) return; // proteção extra
    setState(() => _isLoading = true);

    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final user = authNotifier.user;

    debugPrint('AuthNotifier user no finalizarPedido: $user');

    if (!authNotifier.isAuthenticated || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado ou dados ainda não carregados.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (carrinho.itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seu carrinho está vazio!')),
      );
      setState(() => _isLoading = false);
      return;
    }
    try {
      final pedido = Pedido(
        id: '', // será gerado automaticamente
        numeroPedido: 0,
        userId: user.uid,
        nomeUsuario: user.nome,
        telefone: user.telefone,
        itens: carrinho.itens,
        total: carrinho.total,
        status: 'pendente',
        data: DateTime.now(),
        impresso: false,
      );

      await PedidoService().criarPedido(pedido);

      carrinho.limpar();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido finalizado com sucesso!')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao finalizar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao finalizar pedido')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editarObservacaoDialog(BuildContext context, String produtoId, String? observacaoAtual) {
    final TextEditingController controller = TextEditingController(text: observacaoAtual ?? '');

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
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () {
              final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
              final index = carrinho.itens.indexWhere((item) => item.produto.id == produtoId);
              if (index >= 0) {
                carrinho.atualizarObservacaoPorIndice(index, controller.text.trim());
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = Provider.of<CarrinhoProvider>(context);
    final authNotifier = Provider.of<AuthNotifier>(context);

    if (authNotifier.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authNotifier.user == null) {
      return const Scaffold(
        body: Center(child: Text('Erro ao carregar dados do usuário.')),
      );
    }

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
                    final item = carrinho.itens[index];

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
                                      carrinho.diminuirQuantidadePorIndice(index);
                                    },
                                  ),
                                  Text('${item.quantidade}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      carrinho.aumentarQuantidadePorIndice(index);

                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      carrinho.removerPorIndice(index);
                                    },
                                  ),
                                ],
                              ),
                            if ((item.observacao ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Obs: ${item.observacao}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _editarObservacaoDialog(context, item.produto.id, item.observacao);
                                },
                                icon: const Icon(Icons.edit_note_outlined),
                                label: const Text('Editar observação'),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
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
