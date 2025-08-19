import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/pages/cadastro_produto_page.dart';
import 'package:go_router/go_router.dart';
class AdminProdutosPage extends StatefulWidget {
  @override
  State<AdminProdutosPage> createState() => _AdminProdutosPageState();
}

class _AdminProdutosPageState extends State<AdminProdutosPage> {
  final List<String> categoriasFixas = [
    'Todas',
    'Festividade', 'Bolos', 'Doce', 'Lanches',
    'Pratos', 'Paes', 'Refrigerante', 'Salgados', 'Sucos',
  ];

  String categoriaSelecionada = 'Todas';

  Future<List<Acompanhamento>> carregarTodosAcompanhamentos() async {
    final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
    return snapshot.docs.map((doc) => Acompanhamento.fromMap(doc.data(), doc.id)).toList();
  }

  void toggleDisponivel(String docId, bool atual) async {
    await FirebaseFirestore.instance.collection('produtos').doc(docId).update({'disponivel': !atual});
    setState(() {});
  }

  void _confirmarExclusaoProduto(String produtoId, String nomeProduto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir produto"),
        content: Text("Deseja realmente excluir o produto '$nomeProduto'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('produtos').doc(produtoId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Produto '$nomeProduto' excluído!")),
      );
    }
  }

  void _editarAcompanhamentos(BuildContext context, String produtoId, List<String> acompanhamentosIdsAtuais) async {
    final todosAcompanhs = await carregarTodosAcompanhamentos();
    if (!context.mounted) return;
    final selecionados = List<String>.from(acompanhamentosIdsAtuais);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  Text('Acompanhamentos do Produto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: todosAcompanhs.map((ac) {
                        final isChecked = selecionados.contains(ac.id);
                        return CheckboxListTile(
                          title: Text('${ac.nome} (+R\$${ac.preco.toStringAsFixed(2)})'),
                          value: isChecked,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) selecionados.add(ac.id!);
                              else selecionados.remove(ac.id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('produtos').doc(produtoId).update({
                        'acompanhamentosIds': selecionados,
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acompanhamentos atualizados!')));
                      setState(() {});
                    },
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Painel Admin - Produtos'),
        backgroundColor: Colors.deepOrange,
        automaticallyImplyLeading: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
        tooltip: "Cadastrar novo produto",
        onPressed: () => context.go('/cadastro-produto'),
      ),
      body: Column(
        children: [
          // FILTRO POR CATEGORIA
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categoriasFixas.length,
              itemBuilder: (context, index) {
                final cat = categoriasFixas[index];
                final isSelected = categoriaSelecionada == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        categoriaSelecionada = cat;
                      });
                    },
                    selectedColor: Colors.deepOrange,
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var produtosDocs = snapshot.data!.docs;

                // FILTRO POR CATEGORIA
                if (categoriaSelecionada != 'Todas') {
                  produtosDocs = produtosDocs.where((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return (data['category'] ?? '').toString() == categoriaSelecionada;
                  }).toList();
                }

                if (produtosDocs.isEmpty) return const Center(child: Text('Nenhum produto encontrado.'));

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: produtosDocs.length,
                  itemBuilder: (context, index) {
                    final doc = produtosDocs[index];
                    final data = doc.data()! as Map<String, dynamic>;
                    final produto = Produto.fromMap(data, doc.id);
                    final List<String> acompanhsIds = (data['acompanhamentosIds'] ?? []).map<String>((e) => e.toString()).toList();

                    return Stack(
                      children: [
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.fastfood, size: 60, color: Colors.deepOrange),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(produto.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(produto.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => toggleDisponivel(doc.id, produto.disponivel),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: produto.disponivel ? Colors.green : Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(produto.disponivel ? 'Disponível' : 'Indisponível',
                                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.deepOrange),
                                      onPressed: () => _editarAcompanhamentos(context, doc.id, acompanhsIds),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _confirmarExclusaoProduto(doc.id, produto.nome),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 14,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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
