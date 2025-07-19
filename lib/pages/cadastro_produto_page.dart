import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/product_service.dart';

class CadastroProdutoPage extends StatefulWidget {
  const CadastroProdutoPage({Key? key}) : super(key: key);

  @override
  State<CadastroProdutoPage> createState() => _CadastroProdutoPageState();
}

class _CadastroProdutoPageState extends State<CadastroProdutoPage> {
  final _formKey         = GlobalKey<FormState>();
  final _nomeController  = TextEditingController();
  final _descController  = TextEditingController();
  final _precoController = TextEditingController();
  bool  _disponivel = true;
  bool  _isSaving   = false;
  final _service = ProductService();

  final List<String> _categorias = [
    'Festividade', 'Bolos', 'Doce', 'Lanches',
    'Pratos', 'Paes', 'Refrigerante', 'Salgados', 'Sucos',
  ];
  String? _categoriaSelecionada;

  final List<String> _imagensDisponiveis = [
    'assets/FotosdaPadaria/Baguetes de metro/Baguete01.jpg',
    'assets/FotosdaPadaria/Baguetes de metro/baguetefatia.jpg',
    'assets/FotosdaPadaria/Bolos/BoloSensacao.jpg',
    'assets/FotosdaPadaria/Bolos/BoloChocCastanha.jpg',
    'assets/FotosdaPadaria/Lanches/Americano.png',
    'assets/FotosdaPadaria/LogoeAfins/Paes.jpg',
    'assets/FotosdaPadaria/Outro/Frango_assado.png'
    'assets/FotosdaPadaria/Bolos/BoloCenoura.jpg',
    'assets/LogoNovaAppVinhos.png',
    'assets/LogoPadariaVinhosBranco.png',
    'assets/FotosdaPadaria/Bolos/BoloIndiano.jpg'
  ];

  List<String> _imagemSelecionada = [];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagemSelecionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma imagem')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {

      await _service.saveProduct(
        nome: _nomeController.text.trim(),
        descricao: _descController.text.trim(),
        preco: double.parse(_precoController.text.replaceAll(',', '.')),
        imageUrl: _imagemSelecionada,
        disponivel: _disponivel,
        category: _categoriaSelecionada!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto cadastrado com sucesso!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Produto')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Nome
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Digite o nome' : null,
                  ),
                  const SizedBox(height: 16),

                  // Descrição
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Digite a descrição' : null,
                  ),
                  const SizedBox(height: 16),

                  // Preço
                  TextFormField(
                    controller: _precoController,
                    decoration: const InputDecoration(
                      labelText: 'Preço (ex: 19.90)',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Digite o preço';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Preço inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Disponível
                  SwitchListTile(
                    title: const Text('Disponível'),
                    value: _disponivel,
                    onChanged: (val) => setState(() => _disponivel = val),
                  ),
                  const SizedBox(height: 16),

                  // Categoria
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    value: _categoriaSelecionada,
                    items: _categorias.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    )).toList(),
                    onChanged: (value) => setState(() {
                      _categoriaSelecionada = value;
                    }),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Selecione uma categoria' : null,
                  ),
                  const SizedBox(height: 16),

                  // Botão para selecionar múltiplas imagens
                  const Text('Selecione as imagens do produto:'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3, // ou 2, dependendo do espaço disponível
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 4 / 3,
                    children: _imagensDisponiveis.map((imgPath) {
                      final isSelected = _imagemSelecionada.contains(imgPath);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _imagemSelecionada.remove(imgPath);
                            } else {
                              _imagemSelecionada.add(imgPath);
                            }
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                imgPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.greenAccent,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Botão salvar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Produto'),
                      onPressed: _isSaving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay de loading
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}