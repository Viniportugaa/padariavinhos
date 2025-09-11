import 'package:flutter/material.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/services/acompanhamento_service.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';

class CadastroAcompanhamentoPage extends StatefulWidget {
  const CadastroAcompanhamentoPage({Key? key}) : super(key: key);

  @override
  State<CadastroAcompanhamentoPage> createState() => _CadastroAcompanhamentoPageState();
}

class _CadastroAcompanhamentoPageState extends State<CadastroAcompanhamentoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  bool _disponivel = true;
  bool _isSaving = false;
  final _service = AcompanhamentoService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return

    setState(() => _isSaving = true);

    try {

      final preco = double.parse(_precoController.text.replaceAll(',', '.'));

      final acompanhamento = Acompanhamento(
        nome: _nomeController.text.trim(),
        disponivel: _disponivel,
        preco: preco,
      );

      await _service.salvarAcompanhamento(acompanhamento);

      DialogHelper.showTemporaryToast(context, 'Acompanhamento cadastrado com sucesso!');
      Navigator.of(context).pop();
    } catch (e) {
       DialogHelper.showTemporaryToast(context, 'Erro ao cadastrar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Acompanhamento')),
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
                    validator: (v) => (v == null || v.isEmpty) ? 'Digite o nome' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _precoController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Digite o preço';
                      final preco = double.tryParse(v.replaceAll(',', '.'));
                      if (preco == null) return 'Preço inválido';
                      if (preco < 0) return 'Preço não pode ser negativo';
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Acompanhamento'),
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
