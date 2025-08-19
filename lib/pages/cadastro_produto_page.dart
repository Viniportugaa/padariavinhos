import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  List<File> _imagensSelecionadas = [];

  Future<void> _selecionarImagens() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 75);

    if (pickedFiles != null) {
      setState(() {
        _imagensSelecionadas = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final List<String> uploadedImages = await _service.uploadMultipleImages(_imagensSelecionadas);

      final produto = Produto(
        id: FirebaseFirestore.instance.collection('produtos').doc().id,
        nome: _nomeController.text.trim(),
        descricao: _descController.text.trim(),
        imageUrl: uploadedImages,
        preco: double.parse(_precoController.text.replaceAll(',', '.')),
        disponivel: _disponivel,
        category: _categoriaSelecionada!,
      );

      // Salva produto
      await _service.saveProduct(produto);

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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cadastrar Produto'),
        backgroundColor: Colors.deepOrange,
        automaticallyImplyLeading: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nomeController, 'Nome'),
                  const SizedBox(height: 16),
                  _buildTextField(_descController, 'Descrição', maxLines: 3),
                  const SizedBox(height: 16),
                  _buildTextField(_precoController, 'Preço (ex: 19.90)', prefixText: 'R\$ ', keyboardType: TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Disponível'),
                    value: _disponivel,
                    onChanged: (val) => setState(() => _disponivel = val),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Produto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, String? prefixText, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Digite $label' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Categoria',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _categoriaSelecionada,
      items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _categoriaSelecionada = v),
      validator: (v) => v == null || v.isEmpty ? 'Selecione uma categoria' : null,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecione as imagens do produto:'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _selecionarImagens,
          icon: const Icon(Icons.image),
          label: const Text('Selecionar imagens da Galeria'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _imagensSelecionadas.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (_, index) {
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
                    onTap: () => setState(() => _imagensSelecionadas.removeAt(index)),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 12,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
