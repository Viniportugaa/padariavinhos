import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/provider/provider_local/pedido_local_provider.dart';
import 'package:padariavinhos/pages/local/add_to_cart_local_sheet.dart';

class EditarPedidoLocalPage extends StatefulWidget {
  final String pedidoId;

  const EditarPedidoLocalPage({
    super.key,
    required this.pedidoId,
  });

  @override
  State<EditarPedidoLocalPage> createState() =>
      _EditarPedidoLocalPageState();
}

class _EditarPedidoLocalPageState extends State<EditarPedidoLocalPage> {
  bool carregando = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final provider = context.read<PedidoLocalProvider>();
      await provider.carregarPedidoExistente(widget.pedidoId);
      setState(() => carregando = false);
    });
  }

  // ======================= ADICIONAR ITEM =======================
  Future<void> _adicionarItem() async {
    final provider = context.read<PedidoLocalProvider>();
    final produtos =
    await provider.carregarProdutosComAcompanhamentos();

    final searchCtrl = TextEditingController();
    List<Produto> filtrados = produtos;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Adicionar item"),
          content: SizedBox(
            width: 480,
            height: 520,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: "Buscar produto",
                  ),
                  onChanged: (v) {
                    setStateDialog(() {
                      filtrados = produtos
                          .where((p) => p.nome
                          .toLowerCase()
                          .contains(v.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) {
                      final p = filtrados[i];
                      return ListTile(
                        title: Text(p.nome),
                        subtitle: Text(
                            "R\$ ${p.preco.toStringAsFixed(2)}"),
                        trailing: const Icon(Icons.add),
                        onTap: () {
                          Navigator.pop(ctx);
                          showAddToCartSheetLocal(
                            context,
                            p,
                            p.acompanhamentosDisponiveis,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================= UI =======================
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidoLocalProvider>();

    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/local');
          },
        ),
        title: const Text("Editar Pedido"),
        backgroundColor: Colors.brown.shade600,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: _adicionarItem,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.itens.isEmpty
          ? const Center(child: Text("Pedido vazio"))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.itens.length,
        separatorBuilder: (_, __) =>
        const Divider(height: 1),
        itemBuilder: (_, i) {
          final item = provider.itens[i];

          return Dismissible(
            key: ValueKey(item.idUnico),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: const Icon(Icons.delete,
                  color: Colors.white),
            ),
            onDismissed: (_) =>
                provider.removerItem(item),
            child: ListTile(
              onTap: () => _editarItem(item),
              leading: CircleAvatar(
                backgroundColor: Colors.brown.shade100,
                child: Text("${item.quantidade.toInt()}x"),
              ),
              title: Text(
                item.produto.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  if (item.acompanhamentos?.isNotEmpty ??
                      false)
                    Text(item.acompanhamentos!
                        .map((a) => a.nome)
                        .join(", ")),
                  if (item.observacao?.isNotEmpty ??
                      false)
                    Text(
                      item.observacao!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey),
                    ),
                ],
              ),
              trailing: Text(
                "R\$ ${item.subtotal.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  // ======================= EDITAR ITEM =======================
  void _editarItem(ItemCarrinho item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarItemSheet(itemOriginal: item),
    );
  }
}
class _EditarItemSheet extends StatefulWidget {
  final ItemCarrinho itemOriginal;

  const _EditarItemSheet({required this.itemOriginal});

  @override
  State<_EditarItemSheet> createState() => _EditarItemSheetState();
}

class _EditarItemSheetState extends State<_EditarItemSheet> {
  late Produto produto;
  late List<Acompanhamento> disponiveis;
  late List<Acompanhamento> selecionados;
  late TextEditingController obsCtrl;
  late double quantidade;

  @override
  void initState() {
    super.initState();
    produto = widget.itemOriginal.produto;
    disponiveis = produto.acompanhamentosDisponiveis;
    selecionados =
        List.from(widget.itemOriginal.acompanhamentos ?? []);
    quantidade = widget.itemOriginal.quantidade;
    obsCtrl =
        TextEditingController(text: widget.itemOriginal.observacao);
  }

  void _salvar() {
    final provider = context.read<PedidoLocalProvider>();

    widget.itemOriginal.quantidade = quantidade;
    widget.itemOriginal.observacao = obsCtrl.text;
    widget.itemOriginal.acompanhamentos = selecionados;
    widget.itemOriginal.preco = _precoUnitario();

    provider.notificarAtualizacao(); // notifyListeners()
  }

  double _precoUnitario() {
    double base = produto.preco;
    double adicional = 0;

    const limiteGratis = 3;
    if (selecionados.length > limiteGratis) {
      final extras = selecionados
        ..sort((a, b) => a.preco.compareTo(b.preco));
      for (final a in extras.take(selecionados.length - limiteGratis)) {
        adicional += a.preco;
      }
    }

    return base + adicional;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListView(
          controller: scroll,
          children: [
            Text("Editar ${produto.nome}",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // QTD
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantidade > 1
                        ? () {
                      setState(() => quantidade--);
                      _salvar();
                    }
                        : null),
                Text(quantidade.toInt().toString(),
                    style: const TextStyle(fontSize: 22)),
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => quantidade++);
                      _salvar();
                    }),
              ],
            ),

            const SizedBox(height: 16),

            // ACOMP
            if (disponiveis.isNotEmpty)
              Wrap(
                spacing: 8,
                children: disponiveis.map((a) {
                  final sel =
                  selecionados.any((x) => x.id == a.id);
                  return FilterChip(
                    selected: sel,
                    label: Text(a.nome),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          selecionados.add(a);
                        } else {
                          selecionados
                              .removeWhere((x) => x.id == a.id);
                        }
                      });
                      _salvar();
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                labelText: "Observações",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _salvar(),
            ),
          ],
        ),
      ),
    );
  }
}
