import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:padariavinhos/models/produto.dart';

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
    'assets/FotosdaPadaria/Outro/Frango_assado.png',
    'assets/FotosdaPadaria/Bolos/BoloCenoura.jpg',
    'assets/LogoNovaAppVinhos.png',
    'assets/LogoPadariaVinhosBranco.png',
    'assets/FotosdaPadaria/Bolos/BoloIndiano.jpg',
    'assets/FotosdaPadaria/Pratos/Contra-filé.jpg',
    'assets/FotosdaPadaria/Pratos/Pratofrango.jpg',
    'assets/FotosdaPadaria/Pratos/ftcalabresa.jpg',
    'assets/FotosdaPadaria/Pratos/fthamburguer.jpg',
    'assets/FotosdaPadaria/Pratos/ftrosbife.jpg',
    'assets/FotosdaPadaria/Pratos/parmegiana.jpg'
  ];

  List<File> _imagensSelecionadas = [];
  List<String> _imagensUrls = [];

  Future<void> _selecionarImagens() async{
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 75);

    if(pickedFiles != null){
      setState(() {
        _imagensSelecionadas = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _uploadImagens() async{
    _imagensUrls.clear();

    for(var file in _imagensSelecionadas){
      final nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('produtos/$nomeArquivo.jpg');
      final uploadTask = await storageRef.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      _imagensUrls.add(url);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Faz upload das imagens e obtém URLs
      final List<String> uploadedImages = await _service.uploadMultipleImages(
        _imagensSelecionadas, // sua lista de imagens selecionadas
      );

      // 2. Cria objeto Produto
      final produto = Produto(
        id: FirebaseFirestore.instance.collection('produtos').doc().id,
        nome: _nomeController.text.trim(),
        descricao: _descController.text.trim(),
        imageUrl: uploadedImages,
        preco: double.parse(
          _precoController.text.replaceAll(',', '.'),
        ),
        disponivel: _disponivel,
        category: _categoriaSelecionada!,
      );

      // 3. Salva produto no Firestore
      await _service.saveProduct(produto);

      // 4. Fecha tela e/ou mostra sucesso
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto salvo com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar produto: $e')),
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
                  ElevatedButton.icon(
                    onPressed: _selecionarImagens,
                    icon: const Icon(Icons.image),
                    label: const Text('Selecionar imagens da Galeria'),
                  ),
                  const SizedBox(height: 8),

                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: _imagensSelecionadas.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (_, index){
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imagensSelecionadas[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: (){
                                setState(() {
                                  _imagensSelecionadas.removeAt(index);
                                });
                              },
                              child: const CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 12,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            )
                          )
                        ],
                      );
                    },
                  ),



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