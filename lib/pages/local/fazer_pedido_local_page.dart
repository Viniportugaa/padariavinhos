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

  @override
  void initState() {
    super.initState();
    context.read<ConfigNotifier>().startListening();
    context.read<ProductsNotifier>().startListening();
    _carregarAcompanhamentos();
  }

  Future<void> _carregarAcompanhamentos() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('acompanhamentos').get();
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
    final pedidoLocal = context.read<PedidoLocalProvider>();
    if (pedidoLocal.itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um item antes de revisar.')),
      );
      return;
    }
    final numeroMesa = pedidoLocal.numeroMesa;
    final posicaoMesa = pedidoLocal.posicaoMesa;
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

    return AbertoChecker(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.brown[600],
          elevation: 4,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Pedido Local', style: TextStyle(color: Colors.white)),
              MesaSelectorButton(), // ← PERSISTENTE
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/local-splash'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () => setState(() => _sidebarAberta = !_sidebarAberta),
            ),
          ],
        ),
        body: Row(
          children: [
            // Sidebar recolhível
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _sidebarAberta ? 220 : 0,
              child: _sidebarAberta
                  ? SidebarFilter(
                categorias: categorias,
                selectedCategoria: filtroCategoria,
                onCategoriaChanged: (cat) =>
                    setState(() => filtroCategoria = cat),
                onSearchChanged: (valor) => setState(() => filtroNome = valor),
              )
                  : null,
            ),

            // Área de produtos
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
