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
import 'package:padariavinhos/notifiers/favoritos_provider.dart';
import 'package:padariavinhos/widgets/banner_carousel.dart';
import 'package:collection/collection.dart'; // para firstWhereOrNull
import 'package:padariavinhos/helpers/dialog_helper.dart';

class FazerPedidoPage extends StatefulWidget {
  @override
  State<FazerPedidoPage> createState() => _FazerPedidoPageState();
}

class _FazerPedidoPageState extends State<FazerPedidoPage> {
  List<Acompanhamento> _acompanhamentos = [];
  final ScrollController _scrollController = ScrollController();
  bool _mostrarCategorias = true;
  String filtroNome = '';
  final Map<String, GlobalKey> _produtoKeys = {};
  final double _maxBannerHeight = 180; // altura máxima do banner
  final double _minBannerHeight = 0;   // altura mínima ao encolher
  double _currentBannerHeight = 180;

  @override
  void initState() {
    super.initState();
    final configNotifier = context.read<ConfigNotifier>();
    configNotifier.startListening();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializar();
    });

    _scrollController.addListener(_atualizarAlturaBanner);
  }

  void showTemporaryDialog(BuildContext context, String mensagem, {int segundos = 2}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Text(mensagem),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    Future.delayed(Duration(seconds: segundos), () {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }


  void _abrirProdutoNoCarrinho(String produtoId) {
    final productsNotifier = context.read<ProductsNotifier>();

    // Busca o produto, retorna null se não encontrar
    final Produto? produto = productsNotifier.produtos
        .firstWhereOrNull((p) => p.id == produtoId);

    if (produto != null) {
      _showAddToCartSheet(context, produto);
    } else {
      showTemporaryDialog(context, 'Produto não encontrado.');
    }
  }

  void _atualizarAlturaBanner() {
    final offset = _scrollController.offset;

    // calcula a altura atual do banner
    double newHeight = (_maxBannerHeight - offset).clamp(_minBannerHeight, _maxBannerHeight);

    if (newHeight != _currentBannerHeight) {
      setState(() {
        _currentBannerHeight = newHeight;
      });
    }
  }

  Future<void> _inicializar() async {
    final isOnline = Provider.of<AuthNotifier>(context, listen: false).isOnline;

    if (isOnline) {
      Provider.of<ProductsNotifier>(context, listen: false).startListening();
      await _carregarAcompanhamentos();
    } else {
      showTemporaryDialog(context, 'Conexão ausente. Produtos não carregados.');
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

  @override
  void dispose() {
    _scrollController.removeListener(_atualizarAlturaBanner);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbertoChecker(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: _currentBannerHeight,
                width: double.infinity,
                child: _currentBannerHeight > 0
                    ? BannerCarousel(onBannerTap: _abrirProdutoNoCarrinho)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar produto',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() => filtroNome = valor.toLowerCase());
                  },
                ),
              ),
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
              const SizedBox(height: 8),
              Expanded(child: _buildProdutos()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorias() {
    final favoritosProvider = Provider.of<FavoritosProvider>(context);
    final productsNotifier = Provider.of<ProductsNotifier>(context);
    final categorias = ['Favoritos', ...productsNotifier.categoriasUnicas];

    return ListaCategorias(
      categorias: categorias,
        onSelecionarCategoria: (categoriaSelecionada) {
          productsNotifier.filtrarPorCategoria(categoriaSelecionada);
        },
    );
  }

  Widget _buildProdutos() {
    return Consumer2<ProductsNotifier, FavoritosProvider>(
      builder: (context, notifier, favoritosProvider, _) {
        final isOnline = Provider.of<AuthNotifier>(context).isOnline;

        if (!isOnline) {
          return const Center(
              child: Text('Sem conexão. Catálogo indisponível.'));
        }
        if (notifier.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Produto> produtosFiltrados =
        notifier.produtosFiltrados(favoritosProvider);

        if (filtroNome.isNotEmpty) {
          produtosFiltrados = produtosFiltrados.where((produto) {
            return produto.nome.toLowerCase().contains(filtroNome) ||
                (produto.descricao != null &&
                    produto.descricao!.toLowerCase().contains(filtroNome));
          }).toList();
        }

        if (produtosFiltrados.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        // Agrupa produtos por categoria
        final Map<String, List<Produto>> produtosPorCategoria = {};
        for (var produto in produtosFiltrados) {
          final categoria =
          produto.category.isNotEmpty ? produto.category : 'Outros';
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
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    categoria,
                    style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Pacifico',
                        fontWeight: FontWeight.bold),
                  ),
                ),
                ...produtosDaCategoria.map((produto) {
                  // Só cria a key se ainda não existir
                  final key = _produtoKeys.putIfAbsent(produto.id, () => GlobalKey());

                  return ProductCardHorizontal(
                    key: key,
                    produto: produto,
                    onAddToCart: () => _showAddToCartSheet(context, produto),
                    onViewDetails: () => _showProductDetailsPremium(context, produto),
                  );
                }).toList(),

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

  void _showAddToCartSheet(BuildContext context, Produto produto) {
    int quantidade = 1;
    String observacoes = '';

    final acompanhamentosDisponiveisDoProduto = _acompanhamentos
        .where((a) => produto.acompanhamentosIds.contains(a.id))
        .toList();

    final List<Acompanhamento> selecionados = List.from(produto.acompanhamentosSelecionados ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                double calcularPrecoUnitario() {
                  double precoBase = produto.preco;
                  if (produto.category.toLowerCase() == 'prato' && selecionados.length > 3) {
                    final adicionais = List<Acompanhamento>.from(selecionados.sublist(3));
                    adicionais.sort((a, b) => a.preco.compareTo(b.preco));
                    for (int i = 0; i < adicionais.length; i++) {
                      precoBase += adicionais[i].preco; // 4º cobra menor, 5º segundo menor, etc.
                    }
                  } else if (produto.category.toLowerCase() != 'prato') {
                    precoBase += selecionados.fold(0.0, (soma, a) => soma + a.preco);
                  }
                  return precoBase;
                }

                double precoAcompanhamentoCobrado(Acompanhamento a, int index) {
                  if (produto.category.toLowerCase() == 'prato') {
                    if (selecionados.length <= 3) return 0;
                    final adicionais = List<Acompanhamento>.from(selecionados.sublist(3));
                    adicionais.sort((a, b) => a.preco.compareTo(b.preco));
                    final pos = adicionais.indexOf(a);
                    return pos != -1 ? adicionais[pos].preco : 0;
                  } else {
                    return a.preco;
                  }
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Text(
                          produto.nome,
                          style: const TextStyle(
                            fontFamily: 'Pacifico',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${calcularPrecoUnitario().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Observações (opcional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              onPressed: quantidade > 1
                                  ? () => setState(() => quantidade--)
                                  : null,
                            ),
                            Text(
                              '$quantidade',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => quantidade++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (acompanhamentosDisponiveisDoProduto.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Acompanhamentos:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: acompanhamentosDisponiveisDoProduto
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final a = entry.value;
                                  final index = entry.key;
                                  final isSelected = selecionados.contains(a);
                                  final precoExtra = precoAcompanhamentoCobrado(a, index);

                                  return AnimatedScale(
                                    scale: isSelected ? 1.1 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ChoiceChip(
                                          label: Text(a.nome),
                                          selected: isSelected,
                                          selectedColor: Colors.green[200],
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                selecionados.add(a);
                                              } else {
                                                selecionados.remove(a);
                                              }
                                            });
                                          },
                                        ),
                                        Positioned(
                                          top: -8,
                                          right: -8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: precoExtra > 0 ? Colors.red : Colors.green,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              precoExtra > 0
                                                  ? '+R\$${precoExtra.toStringAsFixed(2)}'
                                                  : 'GRÁTIS',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                              if (produto.category.toLowerCase() == 'prato' && selecionados.length > 3)
                                Text(
                                  'A partir do 4º acompanhamento será cobrado o menor valor selecionado.',
                                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                                ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            final precoUnitario = calcularPrecoUnitario();
                            final total = precoUnitario * quantidade;

                            final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
                            carrinho.adicionarProduto(
                              produto,
                              quantidade.toDouble(),
                              observacao: observacoes,
                              acompanhamentos: selecionados,
                            );

                            final nomesSelecionados =
                            selecionados.map((a) => a.nome).join(', ');

                            Navigator.of(context).pop();
                            DialogHelper.showTemporaryToast(
                              context,
                                  'Adicionado: $quantidade x ${produto.nome}${nomesSelecionados.isNotEmpty ? ' com $nomesSelecionados' : ''}',
                                );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Adicionar ao Carrinho'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


}
