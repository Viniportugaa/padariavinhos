import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padariavinhos/models/banner.dart';
import 'package:padariavinhos/models/produto.dart';

class AdminBannersPage extends StatefulWidget {
  const AdminBannersPage({super.key});

  @override
  State<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends State<AdminBannersPage> {
  final CollectionReference bannersRef =
  FirebaseFirestore.instance.collection('banners');

  final CollectionReference produtosRef =
  FirebaseFirestore.instance.collection('produtos');

  final List<Map<String, String>> diasSemana = [
    {"id": "seg", "label": "Segunda"},
    {"id": "ter", "label": "Terça"},
    {"id": "qua", "label": "Quarta"},
    {"id": "qui", "label": "Quinta"},
    {"id": "sex", "label": "Sexta"},
    {"id": "sab", "label": "Sábado"},
    {"id": "dom", "label": "Domingo"},
  ];

  final ImagePicker _picker = ImagePicker();
  List<Produto> _produtos = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      final snapshot = await produtosRef.get();
      setState(() {
        _produtos = snapshot.docs
            .map((doc) =>
            Produto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
    }
  }

  Future<void> _adicionarBanner() async {
    String? imageUrl;
    String? produtoId;
    List<String> diasSelecionados = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Adicionar Banner',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);

                          if (pickedFile != null) {
                            final fileName =
                                'banners/${DateTime.now().millisecondsSinceEpoch}.png';

                            final ref = FirebaseStorage.instance
                                .ref()
                                .child(fileName);

                            await ref.putFile(File(pickedFile.path));
                            final url = await ref.getDownloadURL();

                            setModalState(() => imageUrl = url);
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                            image: imageUrl != null
                                ? DecorationImage(
                              image: NetworkImage(imageUrl!),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: imageUrl == null
                              ? const Center(
                            child: Icon(Icons.add_a_photo,
                                size: 36, color: Colors.deepOrange),
                          )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: produtoId,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Produto (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('- Nenhum -'),
                          ),
                          ..._produtos.map(
                                (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.nome),
                            ),
                          ),
                        ],
                        onChanged: (val) => produtoId = val,
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Dias visíveis:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Column(
                        children: diasSemana.map((dia) {
                          return CheckboxListTile(
                            title: Text(dia["label"]!),
                            value: diasSelecionados.contains(dia["id"]),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  diasSelecionados.add(dia["id"]!);
                                } else {
                                  diasSelecionados.remove(dia["id"]!);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: imageUrl != null
                            ? () async {
                          await bannersRef.add({
                            'imageUrl': imageUrl,
                            'produtoId': produtoId,
                            'diasVisiveis': diasSelecionados,
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _editarBanner(BannerModel banner) async {
    String imageUrl = banner.imageUrl;
    String? produtoId = banner.produtoId;
    List<String> diasSelecionados = List<String>.from(banner.diasVisiveis);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Editar Banner',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () async {
                          final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            final fileName =
                                'banners/${DateTime.now().millisecondsSinceEpoch}.png';
                            final ref =
                            FirebaseStorage.instance.ref().child(fileName);
                            await ref.putFile(File(pickedFile.path));
                            final url = await ref.getDownloadURL();
                            setModalState(() => imageUrl = url);
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                            image: imageUrl.isNotEmpty
                                ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: imageUrl.isEmpty
                              ? const Center(
                            child: Icon(Icons.add_a_photo,
                                size: 36, color: Colors.deepOrange),
                          )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: produtoId,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Produto (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('- Nenhum -'),
                          ),
                          ..._produtos.map(
                                (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.nome),
                            ),
                          )
                        ],
                        onChanged: (val) => produtoId = val,
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Dias visíveis:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Column(
                        children: diasSemana.map((dia) {
                          return CheckboxListTile(
                            title: Text(dia["label"]!),
                            value: diasSelecionados.contains(dia["id"]),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  diasSelecionados.add(dia["id"]!);
                                } else {
                                  diasSelecionados.remove(dia["id"]!);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: imageUrl.isNotEmpty
                            ? () async {
                          await bannersRef.doc(banner.id).update({
                            'imageUrl': imageUrl,
                            'produtoId': produtoId,
                            'diasVisiveis': diasSelecionados,
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _deletarBanner(String id) async {
    await bannersRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Admin Banners'),
          backgroundColor: Colors.deepOrange),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarBanner,
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bannersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final banners = snapshot.data!.docs
              .map((doc) =>
              BannerModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id))
              .toList();

          if (banners.isEmpty)
            return const Center(child: Text('Nenhum banner cadastrado.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return ListTile(
                leading: Image.network(
                  banner.imageUrl,
                  width: 60,
                  fit: BoxFit.cover,
                ),
                title: Text('Produto ID: ${banner.produtoId ?? "-"}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editarBanner(banner),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletarBanner(banner.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
