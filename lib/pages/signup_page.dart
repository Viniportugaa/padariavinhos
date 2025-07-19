import 'package:flutter/material.dart';

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
        'nome': nameController.text.trim(),
        'endereco': addressController.text.trim(),
        'numero_endereco': addressNumberController.text.trim(),
        'telefone': phoneController.text.trim(),
        'email': emailController.text.trim(),
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
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Nome'),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(hintText: 'Endereço'),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: addressNumberController,
                decoration: const InputDecoration(hintText: 'Número do Endereço'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(hintText: 'Número de Telefone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  PhoneInputFormatter(),
                ],

              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await createUserWithEmailAndPassword();
                },
                child: const Text('SIGN UP'),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(context, LoginPage.route());
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
    );
  }
}