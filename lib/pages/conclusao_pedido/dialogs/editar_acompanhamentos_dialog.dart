import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/pages/conclusao_pedido/controller/conclusao_pedido_controller.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';


class EditarAcompanhamentosDialog {
  static void show(
      BuildContext context,
      int index,
      ItemCarrinho item,
      ConclusaoPedidoController controller,
      ) {
    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

    final acompanhamentosIds = item.produto.acompanhamentosIds;
    final disponiveis = controller.acompanhamentos
        .where((a) => acompanhamentosIds.contains(a.id))
        .toList();

    List<Acompanhamento> selecionados = List.from(item.acompanhamentos ?? []);

    double precoAcompanhamentoCobrado(Acompanhamento a) {
      if (item.produto.category.toLowerCase() == 'pratos') {
        if (selecionados.length <= 3) return 0.0;
        final adicionais = List<Acompanhamento>.from(selecionados.sublist(3));
        adicionais.sort((a, b) => a.preco.compareTo(b.preco));
        final pos = adicionais.indexOf(a);
        return pos != -1 ? adicionais[pos].preco : 0.0;
      } else {
        return a.preco;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Acompanhamentos - ${item.produto.nome}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (disponiveis.isEmpty)
                    const Text('Nenhum acompanhamento disponível para este produto.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: disponiveis.map((a) {
                        final isSelected = selecionados.contains(a);
                        final precoExtra = precoAcompanhamentoCobrado(a);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            FilterChip(
                              label: Text(a.nome),
                              selected: isSelected,
                              selectedColor: Colors.green[200],
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    selecionados.add(a);
                                  } else {
                                    selecionados.remove(a);
                                  }
                                });
                              },
                            ),
                            if (isSelected)
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
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      carrinho.atualizarAcompanhamentos(index, selecionados);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar'),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}