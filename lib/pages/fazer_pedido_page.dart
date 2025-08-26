import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/notifiers/aberto_check.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/widgets/product_card_horizontal.dart';
import 'package:padariavinhos/widgets/lista_categorias.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import '../helpers/acompanhamentos_helper.dart';

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
    final configNotifier = context.read<ConfigNotifier>();
    configNotifier.startListening();
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

  void _verificarDirecaoScroll() {
    if (_scrollController.position.userScrollDirection == AxisDirection.down) {
      if (_mostrarCategorias) setState(() => _mostrarCategorias = false);
    } else if (_scrollController.position.userScrollDirection == AxisDirection.up) {
      if (!_mostrarCategorias) setState(() => _mostrarCategorias = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbertoChecker(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
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
        final isOnline = Provider.of<AuthNotifier>(context).isOnline;

        if (!isOnline) return const Center(child: Text('Sem conexão. Catálogo indisponível.'));
        if (notifier.loading) return const Center(child: CircularProgressIndicator());
        if (notifier.produtosFiltrados.isEmpty) return const Center(child: Text('Nenhum produto disponível'));

        final Map<String, List<Produto>> produtosPorCategoria = {};
        for (var produto in notifier.produtosFiltrados) {
          final categoria = produto.category.isNotEmpty ? produto.category : 'Outros';
          produtosPorCategoria.putIfAbsent(categoria, () => []).add(produto);
        }

        final categoriasOrdenadas = produtosPorCategoria.keys.toList();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categoriasOrdenadas.length,
          itemBuilder: (context, index) {
            final categoria = categoriasOrdenadas[index];
            final produtosDaCategoria = produtosPorCategoria[categoria]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho da categoria
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    categoria,
                    style: const TextStyle(fontSize: 18,fontFamily: 'Pacifico' ,fontWeight: FontWeight.bold),
                  ),
                ),
                // Produtos da categoria
                ...produtosDaCategoria.map((produto) => ProductCardHorizontal(
                  produto: produto,
                  onAddToCart: () => _showAddToCartSheet(context, produto),
                  onViewDetails: () => _showProductDetailsPremium(context, produto),
                )),
              ],
            );
          },
        );
      },
    );
  }

  void _showProductDetailsPremium(BuildContext context, Produto produto) {
    final acompanhamentosDoProduto = _acompanhamentos
        .where((a) => produto.acompanhamentosIds.contains(a.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Para criar efeito flutuante
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagem em destaque com gradiente
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
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Preço
                        Text('R\$ ${produto.preco.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // Descrição
                        if (produto.descricao != null && produto.descricao!.isNotEmpty)
                          Text(produto.descricao!,
                              style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 12),

                        // Acompanhamentos
                        if (acompanhamentosDoProduto.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Acompanhamentos disponíveis:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
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


  void _showAddToCartSheet(BuildContext context, Produto produto) async {
    int quantidade = 1;
    String observacoes = '';

    final acompanhamentosDisponiveisDoProduto = _acompanhamentos
        .where((a) => produto.acompanhamentosIds.contains(a.id))
        .toList();

    final List<Acompanhamento> selecionados = acompanhamentosDisponiveisDoProduto.isNotEmpty
        ? await selecionarAcompanhamentos(
      context: context,
      acompanhamentosDisponiveis: acompanhamentosDisponiveisDoProduto,
      selecionadosIniciais: produto.acompanhamentosSelecionados,
    ) ?? []
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
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
                    Text(produto.nome,
                        style: const TextStyle(
                          fontFamily: 'Pacifico', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green,)),
                    const SizedBox(height: 8),
                    Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valor) => observacoes = valor,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: quantidade > 1 ? () => setState(() => quantidade--) : null,
                        ),
                        Text('$quantidade', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => quantidade++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final precoEstimado = produto.vendidoPorPeso ? produto.preco : produto.preco;
                        final totalEstimado = precoEstimado * quantidade;

                        final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
                        carrinho.adicionarProduto(
                          produto,
                          quantidade.toDouble(),
                          observacao: observacoes,
                          acompanhamentos: selecionados,
                          precoEstimado: precoEstimado,
                        );

                        final nomesSelecionados = selecionados.map((a) => a.nome).join(', ');
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Adicionado: $quantidade x ${produto.nome}${nomesSelecionados.isNotEmpty ? ' com $nomesSelecionados' : ''}',
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
          ),
        );
      },
    );
  }
}
