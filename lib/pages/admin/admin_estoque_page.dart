import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEstoquePedidoPage extends StatefulWidget {
  const AdminEstoquePedidoPage({super.key});

  @override
  State<AdminEstoquePedidoPage> createState() =>
      _AdminEstoquePedidoPageState();
}

class _AdminEstoquePedidoPageState
    extends State<AdminEstoquePedidoPage> {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
  TextEditingController();

  String searchQuery = "";

  CollectionReference get produtosRef =>
      firestore.collection('produtos');

  CollectionReference get pedidosRef =>
      firestore.collection('pedidos');

  DateTime get inicioHoje {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get fimHoje {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// 🔥 Atualiza limite
  Future<void> atualizarLimite(
      String produtoId, int novoLimite) async {

    if (novoLimite < 0) novoLimite = 0;

    await produtosRef.doc(produtoId).update({
      'estoqueLimite': novoLimite,
    });
  }

  /// 🔥 Atualiza estoque manual
  Future<void> atualizarManual(
      String produtoId, int novoValor) async {

    if (novoValor < 0) novoValor = 0;

    await produtosRef.doc(produtoId).update({
      'estoqueManual': novoValor,
    });
  }

  /// 🔥 Atualiza override manual
  Future<void> atualizarDisponibilidadeManual(
      String produtoId, bool valor) async {

    await produtosRef.doc(produtoId).update({
      'disponivelManual': valor,
    });
  }

  /// 🔥 Reset profissional
  Future<void> resetarContagem(String produtoId) async {

    await produtosRef.doc(produtoId).update({
      'estoqueManual': 0,
      'resetPedidosEm': Timestamp.now(),
      'disponivel': true,
    });
  }

  /// 🔥 Atualiza disponibilidade automática
  Future<void> atualizarDisponivelAuto(
      String produtoId, bool disponivelAtual) async {

    await produtosRef.doc(produtoId).update({
      'disponivel': disponivelAtual,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F9),
      appBar: AppBar(
        title: const Text("Estoque Inteligente"),
        centerTitle: true,
      ),
      body: Column(
        children: [

          /// 🔎 PESQUISA
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Pesquisar produto...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery =
                      value.toLowerCase().trim();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: pedidosRef
                  .where(
                'data',
                isGreaterThanOrEqualTo:
                Timestamp.fromDate(inicioHoje),
              )
                  .where(
                'data',
                isLessThanOrEqualTo:
                Timestamp.fromDate(fimHoje),
              )
                  .snapshots(),
              builder: (context, pedidosSnapshot) {

                if (!pedidosSnapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: produtosRef.snapshots(),
                  builder: (context, produtosSnapshot) {

                    if (!produtosSnapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    /// 🔥 MAPA RESET
                    Map<String, Timestamp?> resetMap = {};

                    for (var produto
                    in produtosSnapshot.data!.docs) {
                      final data =
                      produto.data() as Map<String, dynamic>;
                      resetMap[produto.id] =
                      data['resetPedidosEm'];
                    }

                    /// 🔥 CALCULAR PEDIDOS
                    Map<String, int> pedidosHoje = {};

                    for (var pedidoDoc
                    in pedidosSnapshot.data!.docs) {

                      final pedido =
                      pedidoDoc.data()
                      as Map<String, dynamic>;

                      if (pedido['status'] ==
                          "cancelado") continue;

                      final dataPedido =
                      pedido['data'] as Timestamp?;

                      final itens =
                      List<Map<String, dynamic>>
                          .from(pedido['itens'] ?? []);

                      for (var item in itens) {

                        if (item['status'] ==
                            "cancelado") continue;

                        final produtoId =
                        item['produtoId'];
                        if (produtoId == null)
                          continue;

                        final resetTimestamp =
                        resetMap[produtoId];

                        if (resetTimestamp != null &&
                            dataPedido != null &&
                            dataPedido.compareTo(
                                resetTimestamp) <=
                                0) {
                          continue;
                        }

                        final quantidade =
                            (item['quantidade'] as num?)
                                ?.toInt() ?? 1;

                        pedidosHoje.update(
                          produtoId,
                              (value) =>
                          value + quantidade,
                          ifAbsent: () =>
                          quantidade,
                        );
                      }
                    }

                    var produtos =
                        produtosSnapshot.data!.docs;

                    produtos =
                        produtos.where((doc) {
                          final nome =
                          (doc['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          return nome.contains(
                              searchQuery);
                        }).toList();

                    return ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: produtos.length,
                      itemBuilder: (context, index) {

                        final doc = produtos[index];
                        final data =
                        doc.data() as Map<String, dynamic>;

                        final nome = data['nome'] ?? '';
                        final preco =
                        (data['preco'] ?? 0).toDouble();

                        final x =
                            data['estoqueManual'] ?? 0;
                        final z =
                            data['estoqueLimite'] ?? 0;
                        final overrideManual =
                            data['disponivelManual'] ?? true;

                        final y =
                            pedidosHoje[doc.id] ?? 0;

                        final soma = x + y;

                        /// 🔥 REGRA PRINCIPAL
                        bool disponivelCalculado =
                        z == 0 ? true : soma < z;

                        bool disponivelFinal =
                            overrideManual &&
                                disponivelCalculado;

                        /// 🔥 ATUALIZA FIRESTORE AUTOMATICAMENTE
                        if (data['disponivel'] !=
                            disponivelFinal) {
                          atualizarDisponivelAuto(
                              doc.id,
                              disponivelFinal);
                        }

                        final progresso =
                        z == 0 ? 0.0 : soma / z;

                        return Container(
                          margin:
                          const EdgeInsets.only(bottom: 18),
                          padding:
                          const EdgeInsets.all(18),
                          decoration:
                          BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.05),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              /// HEADER + SWITCH CORRIGIDO
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      nome,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Switch(
                                    value: disponivelFinal,
                                    onChanged: (value) async {

                                      // Se atingiu limite, não deixa ligar manualmente
                                      if (!disponivelCalculado && value == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Limite atingido. Não é possível ativar."),
                                          ),
                                        );
                                        return;
                                      }

                                      await atualizarDisponibilidadeManual(
                                        doc.id,
                                        value,
                                      );
                                    },
                                  ),
                                ],
                              ),

                              Text(
                                  "R\$ ${preco.toStringAsFixed(2)}"),

                              const SizedBox(height: 12),

                              Text("Limite: $z"),
                              Text("Manual: $x"),
                              Text("Pedidos: $y"),
                              Text("Total: $soma"),

                              const SizedBox(height: 8),

                              LinearProgressIndicator(
                                value:
                                progresso.clamp(0, 1),
                                minHeight: 8,
                                backgroundColor:
                                Colors.grey.shade300,
                                color: disponivelFinal
                                    ? Colors.green
                                    : Colors.red,
                              ),

                              const SizedBox(height: 16),

                              TextField(
                                keyboardType:
                                TextInputType.number,
                                decoration:
                                const InputDecoration(
                                  labelText:
                                  "Definir limite",
                                  border:
                                  OutlineInputBorder(),
                                ),
                                onSubmitted: (value) {
                                  final novo =
                                      int.tryParse(value) ?? 0;
                                  atualizarLimite(
                                      doc.id, novo);
                                },
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  IconButton(
                                    onPressed: x > 0
                                        ? () =>
                                        atualizarManual(
                                          doc.id,
                                          x - 1,
                                        )
                                        : null,
                                    icon: const Icon(
                                        Icons.remove_circle),
                                  ),
                                  Text(
                                    x.toString(),
                                    style:
                                    const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                    (z == 0 ||
                                        soma < z)
                                        ? () =>
                                        atualizarManual(
                                          doc.id,
                                          x + 1,
                                        )
                                        : null,
                                    icon: const Icon(
                                        Icons.add_circle),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.red,
                                ),
                                onPressed: () =>
                                    resetarContagem(
                                        doc.id),
                                icon:
                                const Icon(Icons.refresh),
                                label: const Text(
                                    "Resetar Contagem"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}