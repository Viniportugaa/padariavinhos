import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // lib para escolher cores
import 'package:cloud_firestore/cloud_firestore.dart';

class CriarCategoriaPage extends StatefulWidget {
  const CriarCategoriaPage({super.key});

  @override
  State<CriarCategoriaPage> createState() => _CriarCategoriaPageState();
}

class _CriarCategoriaPageState extends State<CriarCategoriaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  IconData _iconeSelecionado = Icons.add_circle;
  Color _corSelecionada = Colors.redAccent;

  final List<IconData> _iconesDisponiveis = [
    Icons.cake,
    Icons.bakery_dining,
    Icons.local_drink,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.icecream,
    Icons.add_circle_outline,
    Icons.celebration,
    Icons.restaurant,
    Icons.local_pizza,
    Icons.wine_bar,
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvarCategoria() async {
    if (!_formKey.currentState!.validate()) return;

    final categoria = {
      'nome': _nomeController.text.trim(),
      'icone': _iconeSelecionado.codePoint, // salva o codePoint do ícone
      'iconeFontFamily': _iconeSelecionado.fontFamily, // necessário para restaurar
      'cor': _corSelecionada.value, // salva cor em int
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('categorias').add(categoria);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categoria criada com sucesso!')),
    );

    Navigator.pop(context); // volta para tela anterior
  }

  void _abrirSeletorIcone() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Escolher ícone"),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: GridView.builder(
            itemCount: _iconesDisponiveis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (_, i) {
              final icon = _iconesDisponiveis[i];
              return IconButton(
                icon: Icon(icon,
                    color: icon == _iconeSelecionado ? Colors.blue : Colors.black),
                onPressed: () {
                  setState(() => _iconeSelecionado = icon);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _abrirSeletorCor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Escolher cor"),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _corSelecionada,
            onColorChanged: (color) => setState(() => _corSelecionada = color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Categoria")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome da categoria"),
                validator: (value) =>
                value == null || value.isEmpty ? "Informe o nome" : null,
              ),
              const SizedBox(height: 20),

              // Ícone
              Row(
                children: [
                  const Text("Ícone: "),
                  Icon(_iconeSelecionado, size: 30, color: Colors.black),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _abrirSeletorIcone,
                    child: const Text("Escolher Ícone"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cor
              Row(
                children: [
                  const Text("Cor: "),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _corSelecionada,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _abrirSeletorCor,
                    child: const Text("Escolher Cor"),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvarCategoria,
                  child: const Text("Salvar Categoria"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
