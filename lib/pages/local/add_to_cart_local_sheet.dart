import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:padariavinhos/provider/provider_local/pedido_local_provider.dart';

void showAddToCartSheetLocal(
    BuildContext context,
    Produto produto,
    List<Acompanhamento> acompanhamentosDisponiveis,
    ) {
  int quantidade = 1;
  String observacoes = '';

  // Inicializa 'selecionados' com as instâncias corretas a partir dos IDs do produto
  final List<Acompanhamento> selecionados = [
    for (final s in produto.acompanhamentosSelecionados ?? [])
      if (s.id != null)
        (acompanhamentosDisponiveis.firstWhere(
              (a) => a.id == s.id,
          orElse: () => s,
        ))
  ];

  final pedidoLocal = Provider.of<PedidoLocalProvider>(context, listen: false);
  final mesaSelecionada = pedidoLocal.mesaAtual ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.95,
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              // --- LÓGICA: retornar set de IDs que serão cobrados ---
              Set<String> idsAcompanhamentosCobrados(
                  List<Acompanhamento> selecionadosLocal, Produto produtoLocal) {
                if (produtoLocal.category.toLowerCase() != 'pratos') {
                  // Não é prato: cobra todos
                  return selecionadosLocal
                      .map((e) => e.id)
                      .whereType<String>()
                      .toSet();
                }

                const int limiteGratis = 3;
                if (selecionadosLocal.length <= limiteGratis) return <String>{};

                final int quantidadeCobrada =
                    selecionadosLocal.length - limiteGratis;

                // Ordena por preço (menor -> maior)
                final ordenados = List<Acompanhamento>.from(selecionadosLocal)
                  ..sort((a, b) => a.preco.compareTo(b.preco));

                // Pega os N menores preços
                final cobrados = ordenados.take(quantidadeCobrada).toList();

                return cobrados
                    .map((a) => a.id)
                    .whereType<String>()
                    .toSet();
              }

              // recalcula ids cobrados sempre que build ocorre
              final idsCobrados = idsAcompanhamentosCobrados(selecionados, produto);

              // calcula preço unitário (base + adicionais cobrados)
              double calcularPrecoTotal() {
                double base = produto.preco;
                double adicionais = 0.0;
                for (final a in selecionados) {
                  if (a.id != null && idsCobrados.contains(a.id)) {
                    adicionais += a.preco;
                  }
                }
                return base + adicionais;
              }

              final precoUnitario = calcularPrecoTotal();

              // resumo: grátis, pagos, total adicionais
              Map<String, dynamic> resumoAcompanhamentos() {
                int gratis = 0;
                int pagos = 0;
                double totalAdicionais = 0.0;

                for (final a in selecionados) {
                  if (a.id != null && idsCobrados.contains(a.id)) {
                    pagos++;
                    totalAdicionais += a.preco;
                  } else {
                    gratis++;
                  }
                }

                return {
                  'gratis': gratis,
                  'pagos': pagos,
                  'totalAdicionais': totalAdicionais,
                };
              }

              final resumo = resumoAcompanhamentos();

              // Widget UI
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // drag handle
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // IMAGEM COM HERO + TELA CHEIA
                      if (produto.imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            // abre fullscreen mantendo Hero; não fecha o sheet para manter UI consistente
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  body: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Center(
                                      child: Hero(
                                        tag: produto.id ?? produto.nome,
                                        child: Image.network(
                                          produto.imageUrl.first,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: produto.id ?? produto.nome,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                produto.imageUrl.first,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // NOME
                      Text(
                        produto.nome,
                        style: const TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // PREÇO
                      Text(
                        'R\$ ${precoUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mesa/Posição (se houver)
                      if (mesaSelecionada.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          child: Text(
                            'Mesa $mesaSelecionada',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // OBSERVAÇÕES
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Observações (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                        onChanged: (v) => observacoes = v,
                      ),

                      const SizedBox(height: 14),

                      // QUANTIDADE
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

                      const SizedBox(height: 12),

                      // ACOMPANHAMENTOS
                      if (acompanhamentosDisponiveis.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acompanhamentos:',
                              style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: acompanhamentosDisponiveis.map((a) {
                                final isSelected = selecionados.any((s) => s.id == a.id);
                                final ehCobrado = a.id != null && idsCobrados.contains(a.id);
                                final label = ehCobrado
                                    ? '${a.nome}'
                                    : '${a.nome}';

                                return AnimatedScale(
                                  scale: isSelected ? 1.06 : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeInOut,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        selectedColor: Colors.deepOrange,
                                        backgroundColor: Colors.grey[200],
                                        labelStyle: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              // adiciona instância correta por id (evita duplicados por referência)
                                              final existente = acompanhamentosDisponiveis.firstWhere(
                                                      (x) => x.id == a.id,
                                                  orElse: () => a);
                                              selecionados.add(existente);
                                            } else {
                                              selecionados.removeWhere((x) => x.id == a.id);
                                            }
                                          });
                                        },
                                      ),
                                      // badge de preço / grátis
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: ehCobrado ? Colors.red : Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            ehCobrado
                                                ? '+R\$${a.preco.toStringAsFixed(2)}'
                                                : 'GRÁTIS',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 8),

                            // aviso explicativo para pratos quando houver >3
                            if (produto.category.toLowerCase() == 'pratos' &&
                                selecionados.length > 3)
                              Text(
                                'A partir do 4º acompanhamento serão cobrados os ${selecionados.length - 3} menores selecionados.',
                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                              ),
                          ],
                        ),

                      const SizedBox(height: 18),

                      // resumo (animado)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: selecionados.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                          key: ValueKey(selecionados.length),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.grey[300]),
                            const Text(
                              'Resumo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${resumo['gratis']} grátis • ${resumo['pagos']} pagos (+R\$ ${resumo['totalAdicionais'].toStringAsFixed(2)})',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      // BOTÃO
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                          label: const Text(
                            'Adicionar ao Pedido Local',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            if (mesaSelecionada.isEmpty) {
                              DialogHelper.showTemporaryToast(
                                context,
                                'Mesa não definida.\nSelecione uma mesa antes de adicionar itens.',
                                segundos: 2,
                              );
                              return;
                            }

                            final precoUnitarioFinal = calcularPrecoTotal();

                            final novoItem = ItemCarrinho(
                              produto: produto,
                              quantidade: quantidade.toDouble(),
                              observacao: observacoes,
                              acompanhamentos: List.from(selecionados),
                              preco: precoUnitarioFinal,
                            );


                            try {
                              await pedidoLocal.adicionarItem(novoItem);

                              Navigator.of(context).pop();
                              DialogHelper.showTemporaryToast(
                                context,
                                'Adicionado: $quantidade x ${produto.nome}',
                              );
                            } catch (e) {
                              debugPrint('Erro ao adicionar item local: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro: ${e.toString()}')),
                              );
                            }
                          },
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 12),
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
