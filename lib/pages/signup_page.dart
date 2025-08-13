import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:padariavinhos/pages/cadastro_produto_page.dart';
import 'package:padariavinhos/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  static route() => MaterialPageRoute(
    builder: (context) => const SignUpPage(),
  );
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final addressNumberController = TextEditingController();
  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    addressNumberController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> saveUserData(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nome': nameController.text.trim(),
        'endereco': addressController.text.trim(),
        'numero_endereco': addressNumberController.text.trim(),
        'telefone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'cliente',
        'created_at': Timestamp.now(),
      });
      print('Dados salvos com sucesso!');
    } catch (e) {
      print('Erro ao salvar dados: $e');
    }
  }



  Future<void> createUserWithEmailAndPassword() async {
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print(userCredential.user?.uid);
      final uid = userCredential.user?.uid;
      if (uid != null) {
        await saveUserData(uid);
        print('SALVO');
      }
    } on FirebaseAuthException catch (e) {
      print(e.message);
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
            colors: [
              Colors.green,
              Colors.black,
              Colors.black,
              Colors.red,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo (opcional)
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
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Nome
                _buildInputField(controller: nameController, hint: 'Nome'),
                const SizedBox(height: 15),

                // Endereço
                _buildInputField(controller: addressController, hint: 'Endereço'),
                const SizedBox(height: 15),

                // Número do Endereço
                _buildInputField(
                  controller: addressNumberController,
                  hint: 'Número do Endereço',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),

                // Telefone
                _buildInputField(
                  controller: phoneController,
                  hint: 'Número de Telefone',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                ),
                const SizedBox(height: 15),

                // Email
                _buildInputField(controller: emailController, hint: 'Email'),
                const SizedBox(height: 15),

                // Senha
                _buildInputField(
                  controller: passwordController,
                  hint: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 25),

                // Botão de cadastro
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await createUserWithEmailAndPassword();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Link para login
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, LoginPage.route());
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Componente auxiliar para os campos de texto
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
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