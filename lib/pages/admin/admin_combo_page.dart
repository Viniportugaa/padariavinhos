// pages/admin_combos_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padariavinhos/models/combo.dart';
import 'package:padariavinhos/models/produto.dart';

class AdminCombosPage extends StatefulWidget {
  const AdminCombosPage({super.key});

  @override
  State<AdminCombosPage> createState() => _AdminCombosPageState();
}

class _AdminCombosPageState extends State<AdminCombosPage> {
  final _formKey = GlobalKey<FormState>();

  String nome = '';
  String descricao = '';
  double preco = 0;
  List<String> produtosSelecionados = [];

  bool _loading = false;
  List<Produto> _produtos = [];

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  // Busca produtos do Firestore para o combo
  Future<void> _carregarProdutos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('produtos').get();
      setState(() {
        _produtos = snapshot.docs.map((doc) => Produto.fromMap(doc.data(), doc.id)).toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar produtos')),
      );
    }
  }


  // Salva combo no Firestore
  Future<void> _salvarCombo() async {
    if (!_formKey.currentState!.validate()) return;
    if (produtosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um produto')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final novoCombo = Combo(
        id: '', // Firestore vai gerar
        nome: nome,
        descricao: descricao,
        preco: preco,
        produtosIds: produtosSelecionados,
      );

      final docRef = await FirebaseFirestore.instance.collection('combos').add(novoCombo.toMap());
      await docRef.update({'id': docRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Combo salvo com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Erro ao salvar combo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar combo')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String? _validarPreco(String? value) {
    final preco = double.tryParse(value ?? '');
    if (preco == null || preco <= 0) return 'Informe um preço válido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Combo")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v!.isEmpty ? 'Informe o nome' : null,
                onChanged: (v) => nome = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descrição'),
                onChanged: (v) => descricao = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
                validator: _validarPreco,
                onChanged: (v) => preco = double.tryParse(v) ?? 0,
              ),

              const SizedBox(height: 20),

              const Text(
                'Selecione os produtos do combo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _produtos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _produtos.length,
                itemBuilder: (context, index) {
                  final p = _produtos[index];
                  return CheckboxListTile(
                    title: Text(p.nome),
                    value: produtosSelecionados.contains(p.id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          produtosSelecionados.add(p.id);
                        } else {
                          produtosSelecionados.remove(p.id);
                        }
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarCombo,
                child: const Text("Salvar Combo"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
