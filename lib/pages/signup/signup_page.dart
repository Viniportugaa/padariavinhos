import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/signup/signup_notifier.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/helpers/phone_helper.dart';
import 'package:padariavinhos/widgets/cep_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _acceptedLGPD = false;
  bool _cepValidado = false;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroEnderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _ramalApartamentoController = TextEditingController();

  String _tipoResidencia = 'casa';

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _numeroEnderecoController.dispose();
    _telefoneController.dispose();
    _ramalApartamentoController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedLGPD) {
      DialogHelper.showTemporaryToast(context, 'Aceite a política de privacidade (LGPD).');
      return;
    }

    if (!_cepValidado) {
      DialogHelper.showTemporaryToast(context, "Valide o CEP antes de continuar.");
      return;
    }

    // Valida telefone internacional
    final formattedPhone = PhoneHelper.normalizeToInternational(_telefoneController.text);
    if (!PhoneHelper.isValidInternational(formattedPhone)) {
      DialogHelper.showTemporaryToast(context, 'Telefone inválido. Use apenas números válidos.');
      return;
    }

    final notifier = context.read<SignUpNotifier>();
    final success = await notifier.signUp(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
      telefone: formattedPhone,
      cep: _cepController.text.replaceAll('-', '').trim(),
      endereco: _enderecoController.text.trim(),
      numeroEndereco: _numeroEnderecoController.text.trim(),
      tipoResidencia: _tipoResidencia,
      ramalApartamento: _tipoResidencia == 'apartamento'
          ? _ramalApartamentoController.text.trim()
          : null,
    );

    if (success) {
      DialogHelper.showTemporaryToast(context, 'Cadastro realizado com sucesso!');
      if (mounted) context.go('/splash');
    } else {
      DialogHelper.showTemporaryToast(context, 'Falha ao realizar cadastro. Tente novamente.');
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    bool requiredField = true,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (requiredField && (value == null || value.isEmpty)) return '$label é obrigatório';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SignUpNotifier>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.black, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildInputField(controller: _nomeController, label: "Nome", icon: Icons.person),
                    const SizedBox(height: 16),
                    CepTextField(
                      controller: _cepController,
                      addressController: _enderecoController,
                      onCepValidated: (valido) => setState(() => _cepValidado = valido),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _numeroEnderecoController,
                      label: "Número",
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _enderecoController,
                      label: "Endereço",
                      icon: Icons.home,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _telefoneController,
                      label: "Telefone",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneInputFormatter(defaultCountryCode: 'BR')],
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _senhaController,
                      label: "Senha",
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipoResidencia,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.apartment, color: Colors.white),
                        labelText: 'Tipo de Residência',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'casa', child: Text('Casa', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'apartamento', child: Text('Apartamento', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => _tipoResidencia = v ?? 'casa'),
                    ),
                    const SizedBox(height: 16),
                    if (_tipoResidencia == 'apartamento')
                      _buildInputField(
                        controller: _ramalApartamentoController,
                        label: "Ramal / Apartamento (opcional)",
                        icon: Icons.tag,
                        requiredField: false,
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedLGPD,
                          onChanged: (value) => setState(() => _acceptedLGPD = value ?? false),
                          activeColor: Colors.white,
                          checkColor: Colors.white60,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/lgpd'),
                            child: const Text(
                              "Aceito a política de privacidade (LGPD)",
                              style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (!notifier.isLoading && _cepValidado) ? _onSignUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: notifier.isLoading
                          ? const CircularProgressIndicator(color: Colors.black45)
                          : const Text(
                        "Cadastrar",
                        style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
