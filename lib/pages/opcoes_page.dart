import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter/services.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import '../widgets/cep_text_field.dart';
import 'package:padariavinhos/helpers/phone_helper.dart';
import 'package:padariavinhos/services/entrega_service.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:provider/provider.dart';

class OpcoesPage extends StatefulWidget {
  @override
  _OpcoesPageState createState() => _OpcoesPageState();
}

class _OpcoesPageState extends State<OpcoesPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final addressNumberController = TextEditingController();
  final phoneController = TextEditingController();
  final cepController = TextEditingController();
  final ramalApartamentoController = TextEditingController();

  String _tipoResidencia = 'casa';

  final _cepFormatter = MaskedInputFormatter('#####-###');

  String emailAutenticado = '';
  late String uid;
  bool cepValidado = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? '';
    emailAutenticado = user?.email ?? '';
    loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    addressNumberController.dispose();
    phoneController.dispose();
    cepController.dispose();
    ramalApartamentoController.dispose();
    super.dispose();
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  String _formatCep(String raw) {
    final digits = _onlyDigits(raw);
    if (digits.length != 8) return raw;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      nameController.text = data['nome'] ?? '';
      addressController.text = data['endereco'] ?? '';
      addressNumberController.text = data['numero_endereco'] ?? '';
      phoneController.text = data['telefone'] ?? '';
      cepController.text = _formatCep((data['cep'] ?? '').toString());
      _tipoResidencia = (data['tipo_residencia'] ?? 'casa').toString();
      ramalApartamentoController.text = (data['ramal_apartamento'] ?? '').toString();

      if (mounted) setState(() {});
    }
  }

  // ✅ Função auxiliar modular para excluir conta
  Future<void> deleteAccountWithPassword(String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Navigator.pop(context); // fecha loading
        throw Exception("Nenhum usuário autenticado.");
      }

      final uid = user.uid;

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      final pedidos = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('usuarioId', isEqualTo: uid)
          .get();
      for (var doc in pedidos.docs) {
        await doc.reference.delete();
      }

      final carrinho = await FirebaseFirestore.instance
          .collection('carrinho')
          .where('usuarioId', isEqualTo: uid)
          .get();
      for (var doc in carrinho.docs) {
        await doc.reference.delete();
      }

      await user.delete();

      Navigator.pop(context);

      DialogHelper.showTemporaryToast(context, "A conta e todos os dados foram excluídos com sucesso!");

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Navigator.pop(context); // fecha loading
      print("Erro ao excluir conta: $e");
      DialogHelper.showTemporaryToast(context,  "Erro: ${e.toString()}");
    }
  }

  void confirmarExclusaoConta() {
    final senhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Excluir conta"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Digite sua senha para confirmar a exclusão da conta."),
            SizedBox(height: 10),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              final senha = senhaController.text.trim();
              if (senha.isNotEmpty) {
                Navigator.pop(context);
                deleteAccountWithPassword(senha);
              } else {
                 DialogHelper.showTemporaryToast(context, "Digite a senha para continuar");

              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text("Excluir"),
          ),
        ],
      ),
    );
  }

  Future<void> updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    if (!cepValidado) {
      DialogHelper.showTemporaryToast(context, "Valide o CEP antes de salvar.");
      return;
    }

    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    final cepRaw = _onlyDigits(cepController.text.trim());

    final atualizado = await authNotifier.atualizarEndereco(
      cep: cepRaw,
      endereco: addressController.text.trim(),
      numero: addressNumberController.text.trim(),
      tipoResidencia: _tipoResidencia,
      ramal: _tipoResidencia == 'apartamento'
          ? ramalApartamentoController.text.trim()
          : null,
    );

    if (atualizado) {
      DialogHelper.showTemporaryToast(context, 'Dados atualizados com sucesso!');
    } else {
      DialogHelper.showTemporaryToast(context, 'Erro ao atualizar dados.');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Dados", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.black, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.white, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Email autenticado:',
                      style: theme.textTheme.titleMedium!.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(emailAutenticado,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      )),
                  const SizedBox(height: 24),
                  _buildTextFormField(
                    controller: nameController,
                    label: "Nome",
                    icon: Icons.person,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  CepTextField(
                    controller: cepController,
                    addressController: addressController,
                    onCepValidated: (valido) {
                      setState(() => cepValidado = valido);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: addressNumberController,
                    label: "Número",
                    icon: Icons.format_list_numbered,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: addressController,
                    label: "Endereço",
                    icon: Icons.home,
                    requiredField: false,
                    readOnly: true
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: phoneController,
                    label: "Telefone",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter(defaultCountryCode: 'BR')],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipoResidencia,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        _tipoResidencia == 'apartamento' ? Icons.apartment : Icons.home,
                        color: Colors.black,
                      ),
                      labelText: 'Tipo de Residência',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'casa', child: Text('Casa')),
                      DropdownMenuItem(value: 'apartamento', child: Text('Apartamento')),
                    ],
                    onChanged: (v) => setState(() => _tipoResidencia = v ?? 'casa'),
                  ),
                  if (_tipoResidencia == 'apartamento') ...[
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: ramalApartamentoController,
                      label: "Ramal / Bloco / Apartamento",
                      icon: Icons.tag_rounded,
                      requiredField: false,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: updateUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Salvar Alterações",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: confirmarExclusaoConta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "Excluir Conta",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool requiredField = true,
    TextInputAction textInputAction = TextInputAction.next,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      readOnly: readOnly,
      validator: validator ??
              (value) {
            if (requiredField && (value == null || value.trim().isEmpty)) {
              return '$label não pode ser vazio';
            }
            return null;
          },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}
