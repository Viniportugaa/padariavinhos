import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:padariavinhos/pages/fazer_pedido/add_to_cart_sheet.dart';
import 'package:padariavinhos/helpers/acompanhamentos_helper.dart';

class SugestoesTab extends StatelessWidget {
  final List<Produto> sugestoes;
  final List<Acompanhamento> acompanhamentosDisponiveis;

  const SugestoesTab({
    super.key,
    required this.sugestoes,
    required this.acompanhamentosDisponiveis,
  });

  @override
  Widget build(BuildContext context) {
    if (sugestoes.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma sugestão disponível",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ScrollConfiguration(
        behavior: MyWebScrollBehavior(),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sugestoes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final produto = sugestoes[index];
            final selecionados = produto.acompanhamentosSelecionados ?? [];

            // Preço total já considerando os acompanhamentos selecionados
            final preco = PrecoHelper.calcularPrecoUnitario(
              produto: produto,
              selecionados: selecionados,
            );
            final acompanhamentosFiltrados =
            AcompanhamentoHelper.filtrarAcompanhamentosDoProduto(
              produto: produto,
              acompanhamentosDisponiveis: acompanhamentosDisponiveis,
            );

            return GestureDetector(
              onTap: () {
                showAddToCartSheet(context, produto, acompanhamentosFiltrados);              },
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagem do produto
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                      child: produto.imageUrl != null && produto.imageUrl!.isNotEmpty
                          ? Image.network(
                        produto.imageUrl.first,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome do produto
                            Text(
                              produto.nome,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            // Preço total do produto
                            Text(
                              "R\$ ${preco.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ScrollBehavior para web
class MyWebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
