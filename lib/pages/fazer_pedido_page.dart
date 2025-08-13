import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/widgets/product_grid.dart';
import 'package:padariavinhos/widgets/header_widget.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/widgets/lista_categorias.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

class FazerPedidoPage extends StatefulWidget {

  @override
  State<FazerPedidoPage> createState() => _FazerPedidoPageState();
}

class _FazerPedidoPageState extends State<FazerPedidoPage> {
  List<Acompanhamento> _acompanhamentos = [];

  final ScrollController _scrollController = ScrollController();
  bool _mostrarCategorias = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializar();
    });

    _scrollController.addListener(_verificarDirecaoScroll);
  }

  Future<void> _inicializar() async {
    final isOnline = Provider.of<AuthNotifier>(context, listen: false).isOnline;

    if (isOnline) {
      Provider.of<ProductsNotifier>(context, listen: false).startListening();
      await _carregarAcompanhamentos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conexão ausente. Produtos não carregados.')),
      );
    }
  }

  void _verificarDirecaoScroll() {
    if (_scrollController.position.userScrollDirection == AxisDirection.down) {
      if (_mostrarCategorias) {
        setState(() {
          _mostrarCategorias = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == AxisDirection.up) {
      if (!_mostrarCategorias) {
        setState(() {
          _mostrarCategorias = true;
        });
      }
    }
  }

  Future<void> _carregarAcompanhamentos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
      setState(() {
        _acompanhamentos = snapshot.docs.map((doc) => Acompanhamento.fromMap(doc.data(), doc.id)).toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar acompanhamentos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () =>  context.go('/conclusao-pedido'),
        child: const Icon(Icons.check),
      ),
      // Corpo principal
      body: SafeArea(
        child: Column(
          children: [
            //const HeaderWidget(),
            // const SizedBox(height: 12),
            // const _buildSearchField(),
            const SizedBox(height: 12),
            AnimatedSlide(
              offset: _mostrarCategorias ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              child: AnimatedOpacity(
                opacity: _mostrarCategorias ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _buildCategorias(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Produtos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildProdutos()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorias() {
    final categorias = Provider.of<ProductsNotifier>(context).categoriasUnicas;

    return ListaCategorias(
      categorias: categorias,
      onSelecionarCategoria: (categoriaSelecionada) {
        Provider.of<ProductsNotifier>(context, listen: false)
            .filtrarPorCategoria(categoriaSelecionada);
      },
    );
  }

  Widget _buildProdutos() {
    return Consumer<ProductsNotifier>(
      builder: (context, notifier, _) {
        if (!Provider.of<AuthNotifier>(context).isOnline) {
          return const Center(child: Text('Sem conexão. Catálogo indisponível.'));
        }

        if (notifier.loading) {
          return const Center(child: CircularProgressIndicator());
          debugPrint('Carregando');
        }

        if (notifier.produtos.isEmpty) {
          debugPrint('Esta vazio');

          return const Center(child: Text('Nenhum produto disponível'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: ProductGrid(
            key: ValueKey(notifier.categoriaSelecionada ?? 'todos'),
            produtos: notifier.produtosFiltrados,
            onAddToCart: (produto) => _showAddToCartSheet(context, produto),
            scrollController: _scrollController,
          ),
        );
      },
    );
  }

  // Título "Produtos"
  void _showAddToCartSheet(BuildContext context, Produto produto) {
    int quantidade = 1;
    String observacoes = '';
    List<String> acompanhamentosSelecionados = [];

    final acompanhamentosIds = produto.acompanhamentosIds;

    if (produto.acompanhamentosSelecionados.isNotEmpty) {
      acompanhamentosSelecionados =
          produto.acompanhamentosSelecionados.map((a) => a.nome).toList();
    }


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
              final acompanhamentosDisponiveisDoProduto = _acompanhamentos
                  .where((a) => acompanhamentosIds.contains(a.id))
                  .toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(produto.nome,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),

                  // Campo de observações
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (valor) => observacoes = valor,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  if (acompanhamentosDisponiveisDoProduto.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Acompanhamentos',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: acompanhamentosDisponiveisDoProduto.map((acomp) => FilterChip(
                            label: Text(acomp.nome),
                            selected: acompanhamentosSelecionados.contains(acomp.nome),
                            onSelected: (selecionado) {
                              setState(() {
                                if (selecionado) {
                                  if (acompanhamentosSelecionados.length < 3) {
                                    acompanhamentosSelecionados.add(acomp.nome);
                                  }
                                } else {
                                  acompanhamentosSelecionados.remove(acomp.nome);
                                }
                              });
                            },
                          ))
                              .toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),


                  // Controle de quantidade
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantidade > 1
                            ? () => setState(() => quantidade--)
                            : null,
                      ),
                      Text('$quantidade',
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => quantidade++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botão para confirmar
                  ElevatedButton(
                    onPressed: () {
                      final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

                      final acompanhamentosSelecionadosObjetos = _acompanhamentos
                          .where((a) => acompanhamentosIds.contains(a.nome))
                          .toList();

                      carrinho.adicionar(
                        produto,
                        quantidade,
                        observacao: observacoes,
                        acompanhamentos: acompanhamentosSelecionadosObjetos,
                      );
                      final nomesSelecionados = acompanhamentosSelecionadosObjetos.map((a) => a.nome).join(', ');

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Adicionado: $quantidade x ${produto.nome}'
                              '${nomesSelecionados.isNotEmpty ? 'com $nomesSelecionados' : ''}',
                          ),
                          ),
                      );
                    },
                    child: const Text('Adicionar ao Carrinho'),
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
}
