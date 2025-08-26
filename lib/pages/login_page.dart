import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padariavinhos/pages/menuinicial_page.dart';
import 'package:padariavinhos/pages/signup_page.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> updateFcmToken(String uid) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Para token único:
    await userRef.update({'fcmToken': fcmToken}).catchError((_) {
      // Se o campo não existir ainda, cria
      userRef.set({'fcmToken': fcmToken}, SetOptions(merge: true));
    });

    // Se quiser suportar múltiplos dispositivos por usuário, use array:
    await userRef.update({
      'fcmTokens': FieldValue.arrayUnion([fcmToken])
    }).catchError((_) {
      userRef.set({'fcmTokens': [fcmToken]}, SetOptions(merge: true));
    });
  }

  Future<void> loginUserWithEmailAndPassword(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Usuário não encontrado");

      final uid = user.uid;

      // Atualiza FCM token
      await updateFcmToken(uid);

      // Busca role do usuário
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userDoc.data()?['role'] ?? 'cliente';

      final authNotifier = context.read<AuthNotifier>();
      await authNotifier.login(); // Atualiza estado interno

      if (role == 'admin') {
        context.go('/admin');
      } else {
        context.go('/menu');
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro no login')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
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
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SizedBox(
                    height: 120,
                    child: Image.asset('assets/LogoPadariaVinhosBranco.png'),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: emailController,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o email' : null,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Senha
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    validator: (value) => value != null && value.length < 6
                        ? 'Senha deve ter ao menos 6 caracteres'
                        : null,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  // Botão Login
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                      isLoading ? null : () => loginUserWithEmailAndPassword(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      )
                          : const Text(
                        'LOGIN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link para Signup
                  GestureDetector(
                    onTap: () {
                      context.go('/signup');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Não tem conta? ',
                        style: const TextStyle(color: Colors.white),
                        children: [
                          TextSpan(
                            text: 'Cadastre-se',
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
      ),
    );
  }
}
