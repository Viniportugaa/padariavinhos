import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'package:padariavinhos/notifiers/products_notifier.dart';
import 'package:padariavinhos/helpers/aberto_check.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/pages/fazer_pedido/sections/produto_search_bar.dart';
import 'package:padariavinhos/pages/fazer_pedido/sections/produtos_section.dart';
import 'package:padariavinhos/pages/local/revisar_pedido_local_page.dart';
import 'package:padariavinhos/pages/local/add_to_cart_local_sheet.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/pages/local/provider/pedido_local_provider.dart';
import 'produto_local_section.dart';
import 'package:padariavinhos/pages/local/widget/resumo_pedido.dart';
import 'package:padariavinhos/pages/local/widget/mesa_selector_button.dart';
import 'package:padariavinhos/pages/local/widget/side_bar_filter.dart';
import 'package:go_router/go_router.dart';

class FazerPedidoLocalPage extends StatefulWidget {
  const FazerPedidoLocalPage({super.key});

  @override
  State<FazerPedidoLocalPage> createState() => _FazerPedidoLocalPageState();
}

class _FazerPedidoLocalPageState extends State<FazerPedidoLocalPage> {
  String filtroNome = '';
  String? filtroCategoria;
  List<Acompanhamento> acompanhamentos = [];
  final ScrollController _scrollController = ScrollController();
  bool _sidebarAberta = true;
  bool _carregandoPedido = true;

  @override
  void initState() {
    super.initState();
    _inicializarPagina();
  }

  void _mostrarItensPedido(PedidoLocalProvider pedidoProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final itens = pedidoProvider.itens;

        if (itens.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Nenhum item adicionado ao pedido ainda.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const Text(
                'Itens do Pedido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: itens.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    return ListTile(
                      title: Text(
                        item.produto.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.acompanhamentos != null &&
                              item.acompanhamentos!.isNotEmpty)
                            Text(
                              item.acompanhamentos!
                                  .map((a) => a.nome)
                                  .join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          if (item.observacao?.isNotEmpty ?? false)
                            Text(
                              'Obs: ${item.observacao}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        'R\$ ${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.brown[100],
                        child: Text(
                          '${item.quantidade.toInt()}x',
                          style: const TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'R\$ ${pedidoProvider.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _prosseguirParaRevisao();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Revisar Pedido',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _inicializarPagina() async {
    final config = context.read<ConfigNotifier>();
    final produtos = context.read<ProductsNotifier>();
    final pedidoProvider = context.read<PedidoLocalProvider>();

    config.startListening();
    produtos.startListening();

    // 🔹 Garante que mesa e pedido ativo estão sincronizados
    await pedidoProvider.abrirOuRecuperarPedido();
    await _carregarAcompanhamentos();

    setState(() => _carregandoPedido = false);
  }

  Future<void> _carregarAcompanhamentos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
      setState(() {
        acompanhamentos = snapshot.docs
            .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar acompanhamentos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar acompanhamentos.')),
      );
    }
  }

  void _prosseguirParaRevisao() {
    final pedidoProvider = context.read<PedidoLocalProvider>();
    final numeroMesa = pedidoProvider.numeroMesa;
    final posicaoMesa = pedidoProvider.posicaoMesa;

    if (pedidoProvider.itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um item antes de revisar.')),
      );
      return;
    }

    if (numeroMesa == null || posicaoMesa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a mesa e a posição do cliente.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevisarPedidoLocalPage(
          numeroMesa: numeroMesa,
          posicaoMesa: posicaoMesa,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsNotifier = context.watch<ProductsNotifier>();
    final categorias = productsNotifier.produtos
        .map((p) => p.category.isNotEmpty ? p.category : 'Outros')
        .toSet()
        .toList();

    final pedidoProvider = context.watch<PedidoLocalProvider>();

    if (_carregandoPedido) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.brown),
        ),
      );
    }

    return AbertoChecker(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.brown[600],
          elevation: 4,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Pedido Local', style: TextStyle(color: Colors.white)),
              MesaSelectorButton(),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/local-splash'),
          ),
          actions: [
            // Botão filtro
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () => setState(() => _sidebarAberta = !_sidebarAberta),
            ),

            // 🔹 Botão Carrinho com contador
            Consumer<PedidoLocalProvider>(
              builder: (context, pedidoProvider, _) {
                final qtdItens = pedidoProvider.itens.length;

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      tooltip: 'Ver pedido',
                      onPressed: () => _mostrarItensPedido(pedidoProvider),
                    ),
                    if (qtdItens > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$qtdItens',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),

        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _sidebarAberta ? 220 : 0,
              child: _sidebarAberta
                  ? SidebarFilter(
                categorias: categorias,
                selectedCategoria: filtroCategoria,
                onCategoriaChanged: (cat) =>
                    setState(() => filtroCategoria = cat),
                onSearchChanged: (valor) =>
                    setState(() => filtroNome = valor),
              )
                  : null,
            ),
            Expanded(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.only(left: _sidebarAberta ? 16 : 0),
                child: Column(
                  children: [
                    Expanded(
                      child: ProdutosLocalSection(
                        filtroNome: filtroNome,
                        filtroCategoria: filtroCategoria,
                        acompanhamentos: acompanhamentos,
                        scrollController: _scrollController,
                      ),
                    ),
                    ResumoPedido(onRevisarPedido: _prosseguirParaRevisao),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
