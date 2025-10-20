import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido_local.dart';
import 'package:padariavinhos/pages/local/provider/pedido_local_provider.dart';

class RevisarPedidoLocalPage extends StatefulWidget {
  final String numeroMesa;
  final int posicaoMesa;

  const RevisarPedidoLocalPage({
    super.key,
    required this.numeroMesa,
    required this.posicaoMesa,
  });

  @override
  State<RevisarPedidoLocalPage> createState() => _RevisarPedidoLocalPageState();
}

class _RevisarPedidoLocalPageState extends State<RevisarPedidoLocalPage> {
  bool isLoading = false;
  final observacoesController = TextEditingController();
  String? formaPagamento;
  double? gorjetaPercentual;

  final List<String> formas = [
    'Pix',
    'Dinheiro',
    'Cartão Débito',
    'Cartão Crédito',
    'Fiado',
  ];

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }

  Future<void> _enviarPedido(BuildContext context) async {
    final pedidoProvider = context.read<PedidoLocalProvider>();
    final itens = pedidoProvider.itens;

    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione itens ao pedido antes de enviar.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final agora = DateTime.now();
      final pedido = PedidoLocal(
        id: '',
        mesa: widget.numeroMesa,
        posicao: widget.posicaoMesa,
        itens: itens,
        status: 'pendente',
        data: agora,
        horaFormatada: DateFormat('HH:mm').format(agora),
        observacoes: observacoesController.text.trim().isEmpty
            ? null
            : observacoesController.text.trim(),
      );

      final pedidosRef = FirebaseFirestore.instance.collection('pedidos_local');
      final docRef = await pedidosRef.add(pedido.toMap());
      await pedidosRef.doc(docRef.id).update({
        'id': docRef.id,
        'formaPagamento': formaPagamento ?? 'Não informado',
        'gorjeta': gorjetaPercentual ?? 0,
      });

      pedidoProvider.limparItens();

      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidoProvider = context.watch<PedidoLocalProvider>();
    final total = pedidoProvider.total;
    final itens = pedidoProvider.itens;

    final double gorjetaValor =
    (gorjetaPercentual != null ? total * (gorjetaPercentual! / 100) : 0);
    final double totalComGorjeta = total + gorjetaValor;

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Revisar Pedido'),
        centerTitle: true,
        backgroundColor: Colors.brown[700],
      ),
      body: itens.isEmpty
          ? const Center(
        child: Text(
          'Nenhum item no pedido.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Cabeçalho
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa ${widget.numeroMesa}  |  P${widget.posicaoMesa + 1}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Horário: ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              itemCount: itens.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = itens[index];
                final acompanhamentos = item.acompanhamentos ?? [];

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Cabeçalho: Nome + preço + quantidade
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Nome + Preço
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.produto.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'R\$ ${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Controles de quantidade
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.brown),
                                  onPressed: () => context
                                      .read<PedidoLocalProvider>()
                                      .diminuirQuantidade(item),
                                ),
                                Text('${item.quantidade}',
                                    style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: Colors.brown),
                                  onPressed: () => context
                                      .read<PedidoLocalProvider>()
                                      .aumentarQuantidade(item),
                                ),
                              ],
                            ),

                            // Excluir item
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                context.read<PedidoLocalProvider>().removerItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                      Text('${item.produto.nome} removido do pedido.')),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // 🔹 Acompanhamentos
                        if (acompanhamentos.isNotEmpty) ...[
                          const Divider(),
                          const Text(
                            'Acompanhamentos:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.brown,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: -4,
                            children: acompanhamentos
                                .map((a) => Chip(
                              label: Text(
                                a.nome,
                                style: const TextStyle(fontSize: 13),
                              ),
                              backgroundColor: Colors.brown[100],
                            ))
                                .toList(),
                          ),
                        ],

                        // 🔹 Observação do item
                        if (item.observacao != null &&
                            item.observacao!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment_outlined,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.observacao!,
                                  style:
                                  const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // 🔹 Total com gorjeta
            Container(
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('R\$ ${total.toStringAsFixed(2)}'),
                      if (gorjetaValor > 0)
                        Text(
                          '+ Gorjeta: R\$ ${gorjetaValor.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Final: R\$ ${totalComGorjeta.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // 🔹 Botão fixo inferior
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Icon(Icons.send),
          label: Text(
            isLoading ? 'Enviando...' : 'Finalizar Pedido',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[700],
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isLoading ? null : () => _enviarPedido(context),
        ),
      ),
    );
  }
}
