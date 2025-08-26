import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padariavinhos/services/cep_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  bool acceptedLGPD = false;
  bool isLoadingCep = false;
  bool isLoading = false;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final cepController = TextEditingController();
  final enderecoController = TextEditingController();
  final numeroEnderecoController = TextEditingController();
  final telefoneController = TextEditingController();
  final ramalApartamentoController = TextEditingController();
  String tipoResidencia = 'casa';

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    cepController.dispose();
    enderecoController.dispose();
    numeroEnderecoController.dispose();
    telefoneController.dispose();
    ramalApartamentoController.dispose();
    super.dispose();
  }

  Future<void> saveUserData(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'nome': nomeController.text.trim(),
      'endereco': enderecoController.text.trim(),
      'numero_endereco': numeroEnderecoController.text.trim(),
      'telefone': telefoneController.text.trim(),
      'cep': cepController.text.trim(),
      'email': emailController.text.trim(),
      'role': 'cliente',
      'tipo_residencia': tipoResidencia,
      'ramal_apartamento': tipoResidencia == 'apartamento'
          ? ramalApartamentoController.text.trim()
          : null,
      'created_at': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String uid) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userDoc.data()?['role'] ?? 'cliente';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .doc(fcmToken)
          .set({
        'created_at': Timestamp.now(),
        'last_used': Timestamp.now(),
        'role': role,
      });
    }
  }

  Future<void> buscarEnderecoPorCep(String cep) async {
    setState(() => isLoadingCep = true);
    final endereco = await CepService.buscarEndereco(cep);
    setState(() => isLoadingCep = false);

    if (endereco != null) {
      enderecoController.text =
      "${endereco["logradouro"]}, ${endereco["bairro"]}, ${endereco["cidade"]} - ${endereco["estado"]}";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CEP inválido ou não encontrado.")),
      );
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;
    if (!acceptedLGPD) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite a política de privacidade (LGPD).')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1️⃣ Cria usuário no Firebase Auth
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // 2️⃣ Salva dados no Firestore
      await saveUserData(uid);

      // 3️⃣ Salva FCM Token
      await saveFcmToken(uid);

      setState(() => isLoading = false);

      // 4️⃣ Feedback e redirecionamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );
      context.push('/signin');

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar usuário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green, Colors.black, Colors.black, Colors.red],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  height: 100,
                  child: Image.asset(
                    'assets/LogoPadariaVinhosBranco.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Sign Up',
                  style: TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 30),
                _buildInputField(controller: nomeController, hint: 'Nome'),
                const SizedBox(height: 15),
                TextFormField(
                  controller: cepController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'CEP',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _buildBotaoCep(),
                  ),
                  validator: (value) =>
                  (value == null || value.length != 8) ? 'CEP inválido' : null,
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tipo de residência",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    RadioListTile<String>(
                      value: 'casa',
                      groupValue: tipoResidencia,
                      onChanged: (value) => setState(() => tipoResidencia = value!),
                      activeColor: Colors.white,
                      title: const Text("Casa", style: TextStyle(color: Colors.white)),
                    ),
                    RadioListTile<String>(
                      value: 'apartamento',
                      groupValue: tipoResidencia,
                      onChanged: (value) => setState(() => tipoResidencia = value!),
                      activeColor: Colors.white,
                      title: const Text("Apartamento", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildInputField(
                    controller: numeroEnderecoController,
                    hint: tipoResidencia == 'casa' ? 'Número' : 'Número',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                _buildInputField(
                    controller: ramalApartamentoController,
                    hint: 'Complemento/Ramal',
                    requiredField: false),
                const SizedBox(height: 15),
                _buildInputField(controller: enderecoController, hint: 'Endereço'),
                const SizedBox(height: 15),
                _buildInputField(
                    controller: telefoneController,
                    hint: 'Telefone',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()]),
                const SizedBox(height: 15),
                _buildInputField(controller: emailController, hint: 'Email'),
                const SizedBox(height: 15),
                _buildInputField(
                    controller: senhaController, hint: 'Senha', obscureText: true),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Checkbox(
                      value: acceptedLGPD,
                      onChanged: (value) => setState(() => acceptedLGPD = value ?? false),
                      activeColor: Colors.white,
                      checkColor: Colors.black,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/lgpd'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(text: 'Aceito a política de privacidade '),
                          TextSpan(
                            text: '(LGPD)',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : createUserWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('SIGN UP',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => context.push('/signin'),
                  child: const Text(
                    'Já tem uma conta? Faça login',
                    style: TextStyle(
                        color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoCep() {
    return IconButton(
      icon: isLoadingCep
          ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
          : const Icon(Icons.search, color: Colors.white),
      onPressed: () {
        if (cepController.text.trim().length == 8) {
          buscarEnderecoPorCep(cepController.text.trim());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Digite um CEP válido (8 números)")),
          );
        }
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (requiredField && (value == null || value.isEmpty)) {
          return 'Campo obrigatório';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIconColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
