import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';

void showAddToCartSheet(BuildContext context, Produto produto, List<Acompanhamento> acompanhamentosDisponiveis) {
  int quantidade = 1;
  String observacoes = '';

  // Inicializa 'selecionados' com as instâncias correspondentes em acompanhamentosDisponiveis (por id)
  final List<Acompanhamento> selecionados = [
    for (final s in produto.acompanhamentosSelecionados ?? [])
      if (s.id != null)
        (acompanhamentosDisponiveis.firstWhere(
              (a) => a.id == s.id,
          orElse: () => s,
        ))
  ];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              // --- Função que decide, de forma determinística, quais IDs serão cobrados ---
              Set<String> calcularIdsCobrados(List<Acompanhamento> selecionadosLocal, Produto produtoLocal) {
                // se não for prato, todos cobrados (por id)
                if (produtoLocal.category.toLowerCase() != 'pratos') {
                  return selecionadosLocal.map((e) => e.id).whereType<String>().toSet();
                }

                const int limiteGratis = 3;
                if (selecionadosLocal.length <= limiteGratis) return <String>{};

                final numeroACobrar = selecionadosLocal.length - limiteGratis;

                // Regra anterior: pega os menores preços para cobrar (valor mais baixo)
                // 1) cria lista de preços ordenada (do menor para o maior)
                final precosOrdenados = selecionadosLocal.map((e) => e.preco).toList()..sort();

                // 2) pega os menores N preços que serão cobrados
                final valoresACobrar = precosOrdenados.take(numeroACobrar).toList();

                // 3) contagem de quantas vezes cada valor precisa ser cobrado
                final Map<double, int> contagemValores = {};
                for (var v in valoresACobrar) {
                  contagemValores[v] = (contagemValores[v] ?? 0) + 1;
                }

                // 4) agora percorre os selecionados NA ORDEM DE SELEÇÃO e marca como cobrados
                //    quando encontrar um preço que ainda tem contagem > 0, decremente e marque o id
                final Set<String> ids = {};
                for (final a in selecionadosLocal) {
                  final p = a.preco;
                  if (contagemValores.containsKey(p) && contagemValores[p]! > 0) {
                    ids.add(a.id ?? '');
                    contagemValores[p] = contagemValores[p]! - 1;
                  }
                }

                // filtra ids vazios/nulos (por segurança)
                ids.removeWhere((id) => id.isEmpty);
                return ids;
              }

              // Precompute ids cobrados a cada build, usando 'selecionados' atual
              final idsCobrados = calcularIdsCobrados(selecionados, produto);

              // Preço unitário (usado no topo)
              double precoUnitario = PrecoHelper.calcularPrecoUnitario(
                produto: produto,
                selecionados: selecionados,
              );


              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
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

                      if (produto.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            produto.imageUrl.first,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      // Nome do produto
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

                      // Preço
                      Text(
                        'R\$ ${precoUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Observações
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

                      // Quantidade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: quantidade > 1 ? () => setState(() => quantidade--) : null,
                          ),
                          Text(
                            '$quantidade',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => quantidade++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Acompanhamentos
                      if (acompanhamentosDisponiveis.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acompanhamentos:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: acompanhamentosDisponiveis.asMap().entries.map((entry) {
                                final a = entry.value;
                                // Seleção comparando por id (evita problemas de referência)
                                final isSelected = selecionados.any((s) => s.id == a.id);

                                // precoExtra determinado pela lista de ids cobrados calculada
                                final precoExtra = idsCobrados.contains(a.id) ? a.preco : 0.0;

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
                            if (produto.category.toLowerCase() == 'pratos' && selecionados.length > 3)
                              Text(
                                'A partir do 4º acompanhamento será cobrado o menor valor selecionado.',
                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Botão Adicionar ao Carrinho
                      ElevatedButton.icon(
                        onPressed: () {
                          final precoUnitario = PrecoHelper.calcularPrecoUnitario(
                            produto: produto,
                            selecionados: selecionados,
                          );

                          Text(
                            'R\$ ${precoUnitario.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );

                          final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
                          carrinho.adicionarProduto(
                            produto,
                            quantidade.toDouble(),
                            observacao: observacoes,
                            acompanhamentos: List.from(selecionados),
                          );

                          final nomesSelecionados = selecionados.map((a) => a.nome).join(', ');

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
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 80),
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