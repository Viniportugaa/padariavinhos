import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';

class AdminProdutosPage extends StatefulWidget {
  @override
  State<AdminProdutosPage> createState() => _AdminProdutosPageState();
}

class _AdminProdutosPageState extends State<AdminProdutosPage> {
  Future<List<Acompanhamento>> carregarTodosAcompanhamentos() async {
    final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Acompanhamento.fromMap(data, doc.id);
    }).toList();
  }

  void toggleDisponivel(String docId, bool atual) async {
    await FirebaseFirestore.instance
        .collection('produtos')
        .doc(docId)
        .update({'disponivel': !atual});
    setState(() {});
  }

  void _editarAcompanhamentos(BuildContext context, String produtoId, List<String> acompanhamentosIdsAtuais) async {
    final todosAcompanhs = await carregarTodosAcompanhamentos();

    if (!context.mounted) return;

    final selecionados = List<String>.from(acompanhamentosIdsAtuais);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Acompanhamentos do Produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: todosAcompanhs.map((ac) {
                        final isChecked = selecionados.contains(ac.id);
                        return CheckboxListTile(
                          title: Text('${ac.nome} (+R\$${ac.preco.toStringAsFixed(2)})'),
                          value: isChecked,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selecionados.add(ac.id!);
                              } else {
                                selecionados.remove(ac.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('produtos').doc(produtoId).update({
                        'acompanhamentosIds': selecionados,
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acompanhamentos atualizados!')));
                      setState(() {});
                    },
                    child: const Text('Salvar'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin - Produtos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final produtosDocs = snapshot.data!.docs;

          if (produtosDocs.isEmpty) return const Center(child: Text('Nenhum produto encontrado.'));

          return ListView.builder(
            itemCount: produtosDocs.length,
            itemBuilder: (context, index) {
              final doc = produtosDocs[index];
              final data = doc.data()! as Map<String, dynamic>;

              final produto = Produto.fromMap(data, doc.id);

              // O campo 'acompanhamentosIds' pode não existir
              final List<dynamic> acompanhsIdsDynamic = data['acompanhamentosIds'] ?? [];
              final List<String> acompanhsIds = acompanhsIdsDynamic.map((e) => e.toString()).toList();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(produto.descricao),
                  trailing: Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () => toggleDisponivel(doc.id, produto.disponivel),
                        child: Text(produto.disponivel ? 'Disponível' : 'Indisponível'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: produto.disponivel ? Colors.green : Colors.red,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _editarAcompanhamentos(context, doc.id, acompanhsIds),
                        child: const Text('Editar Acompanhamentos'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
