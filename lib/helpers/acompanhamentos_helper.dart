import 'package:flutter/material.dart';
import '../models/acompanhamento.dart';
import 'package:padariavinhos/models/produto.dart';

class AcompanhamentoHelper {
  static List<Acompanhamento> filtrarAcompanhamentosDoProduto({
    required Produto produto,
    required List<Acompanhamento> acompanhamentosDisponiveis,
  }) {
    return acompanhamentosDisponiveis
        .where((a) => produto.acompanhamentosIds.contains(a.id))
        .toList();
  }
}

Future<List<Acompanhamento>?> selecionarAcompanhamentos({
  required BuildContext context,
  required List<Acompanhamento> acompanhamentosDisponiveis,
  List<Acompanhamento>? selecionadosIniciais,
  int maxSelecionados = 3,
  String titulo = 'Selecionar Acompanhamentos',
}) async {
  List<String> selecionadosNomes = List.from(
      selecionadosIniciais?.map((a) => a.nome) ?? []
  );

  return showModalBottomSheet<List<Acompanhamento>>(
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
                Text(titulo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                acompanhamentosDisponiveis.isEmpty
                    ? const Text('Nenhum acompanhamento disponível.')
                    : Wrap(
                  spacing: 8,
                  children: acompanhamentosDisponiveis.map((acomp) {
                    final isSelected = selecionadosNomes.contains(acomp.nome);
                    return FilterChip(
                      label: Text(acomp.nome),
                      selected: isSelected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            if (selecionadosNomes.length < maxSelecionados) {
                              selecionadosNomes.add(acomp.nome);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Máximo de $maxSelecionados acompanhamentos.')),
                              );
                            }
                          } else {
                            selecionadosNomes.remove(acomp.nome);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final selecionadosObjetos = acompanhamentosDisponiveis
                        .where((a) => selecionadosNomes.contains(a.nome))
                        .toList();
                    Navigator.of(context).pop(selecionadosObjetos);
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
