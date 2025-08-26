import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/aberto_check.dart';
import '../helpers/acompanhamentos_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConclusaoPedidoPage extends StatefulWidget {
  @override
  State<ConclusaoPedidoPage> createState() => _ConclusaoPedidoPageState();
}

class _ConclusaoPedidoPageState extends State<ConclusaoPedidoPage> {
  bool _isLoading = false;
  String _formaPagamento = 'Pix';
  final List<String> _formasPagamento = ['Pix', 'Débito', 'Crédito', 'Voucher', 'Dinheiro'];
  List<Acompanhamento> _acompanhamentos = [];

  @override
  void initState() {
    super.initState();
    _carregarAcompanhamentos();
  }

  Future<void> _carregarAcompanhamentos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
      setState(() {
        _acompanhamentos = snapshot.docs
            .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar acompanhamentos: $e');
    }
  }

  void _finalizarPedido() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final user = authNotifier.user;

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
        id: '',
        numeroPedido: 0,
        userId: user.uid,
        nomeUsuario: user.nome,
        telefone: user.telefone,
        itens: carrinho.itens,
        status: 'pendente',
        data: DateTime.now(),
        impresso: false,
        endereco: user.enderecoFormatado,
        formaPagamento: _formasPagamento,
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

  void _editarAcompanhamentosDialog(BuildContext context, int index, ItemCarrinho item) {
    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

    final acompanhamentosIds = item.produto.acompanhamentosIds;
    final acompanhamentosDisponiveisDoProduto = _acompanhamentos
        .where((a) => acompanhamentosIds.contains(a.id))
        .toList();

    List<String> selecionadosNomes = List.from(item.acompanhamentos?.map((a) => a.nome) ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Acompanhamentos - ${item.produto.nome}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (acompanhamentosDisponiveisDoProduto.isEmpty)
                    const Text('Nenhum acompanhamento disponível para este produto.')
                  else
                    Wrap(
                      spacing: 8,
                      children: acompanhamentosDisponiveisDoProduto.map((acomp) {
                        final isSelected = selecionadosNomes.contains(acomp.nome);
                        return FilterChip(
                          label: Text(acomp.nome),
                          selected: isSelected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                if (selecionadosNomes.length < 3) {
                                  selecionadosNomes.add(acomp.nome);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Máximo de 3 acompanhamentos.')),
                                  );
                                }
                              } else {
                                selecionadosNomes.remove(acomp.nome);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final selecionadosObjetos = _acompanhamentos
                          .where((a) => selecionadosNomes.contains(a.nome))
                          .toList();
                      carrinho.atualizarAcompanhamentosPorIndice(index, selecionadosObjetos);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar'),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbertoChecker(
      child: Builder(
        builder: (context) {
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

          final user = authNotifier.user!;

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
                      onPressed: () => context.go('/pedido'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                    const SizedBox(height: 12),
                    // Cartão de Endereço
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.enderecoFormatado,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cartão de Forma de Pagamento
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.payment, color: Colors.green),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Forma de Pagamento (Devem ser feitos no local):',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            DropdownButton<String>(
                              value: _formaPagamento,
                              items: _formasPagamento
                                  .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _formaPagamento = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Lista de Itens do Pedido
                    Expanded(
                      child: ListView.separated(
                        itemCount: carrinho.itens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = carrinho.itens[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.produto.nome,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              'Qtd: ${item.quantidade}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            if ((item.observacao ?? '').isNotEmpty)
                                              Text(
                                                'Obs: ${item.observacao}',
                                                style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 14),
                                              ),
                                            if ((item.acompanhamentos ?? []).isNotEmpty)
                                              Text(
                                                'Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}',
                                                style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 14),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline),
                                                onPressed: () {
                                                  carrinho.diminuirQuantidadePorIndice(index);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline),
                                                onPressed: () {
                                                  carrinho.aumentarQuantidadePorIndice(index);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                onPressed: () {
                                                  carrinho.removerPorIndice(index);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          _editarObservacaoDialog(
                                              context, item.produto.id, item.observacao);
                                        },
                                        icon: const Icon(Icons.edit_note_outlined),
                                        label: const Text('Editar Obs'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          _editarAcompanhamentosDialog(
                                              context, index, item);
                                        },
                                        icon: const Icon(Icons.fastfood),
                                        label: const Text('Editar Acomp.'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'R\$ ${carrinho.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Botão Finalizar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
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
        },
      ),
    );
  }
}