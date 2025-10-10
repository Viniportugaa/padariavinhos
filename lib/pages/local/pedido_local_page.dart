import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/pedido.dart';

class PedidoLocalPage extends StatefulWidget {
  const PedidoLocalPage({super.key});

  @override
  State<PedidoLocalPage> createState() => _PedidoLocalPageState();
}

class _PedidoLocalPageState extends State<PedidoLocalPage> {
  final List<ItemCarrinho> _carrinho = [];
  final TextEditingController _mesaController = TextEditingController();

  double get _total => _carrinho.fold(
      0, (total, item) => total + (item.produto.preco * item.quantidade));

  Future<void> _enviarPedido() async {
    if (_mesaController.text.isEmpty || _carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe a mesa e adicione produtos.")),
      );
      return;
    }


    setState(() {
      _carrinho.clear();
      _mesaController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pedido enviado ao balcão com sucesso!")),
    );
  }

  void _adicionarAoCarrinho(Produto produto) {
    final existente = _carrinho.firstWhere(
          (item) => item.produto.id == produto.id,
      orElse: () => ItemCarrinho(produto: produto, quantidade: 0, preco: 0),
    );

    if (existente.quantidade > 0) {
      existente.quantidade++;
    } else {
      _carrinho.add(ItemCarrinho(produto: produto, quantidade: 1, preco: 0));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Autoatendimento - Mesa Local"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mesaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Número da Mesa",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _enviarPedido,
                  icon: const Icon(Icons.check),
                  label: const Text("Enviar Pedido"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('produtos')
                  .where('disponivel', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum produto disponível."));
                }

                final produtos = snapshot.data!.docs
                    .map((doc) =>
                    Produto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4 / 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _adicionarAoCarrinho(produto),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: Image.network(
                                  produto.imageUrl.first,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(produto.nome,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text("R\$ ${produto.preco.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_carrinho.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Itens: ${_carrinho.length}",
                      style: const TextStyle(fontSize: 16)),
                  Text("Total: R\$ ${_total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
