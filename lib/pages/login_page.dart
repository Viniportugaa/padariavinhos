import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/services/notification_service.dart';
import 'package:padariavinhos/services/auth_service.dart';

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
    await NotificationService.initFCM(uid);

  }

  Future<void> loginUser(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final authNotifier = context.read<AuthNotifier>();
      final authService = AuthService();

      // Login com Firebase
      final user = await authService.loginWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user == null) throw Exception("Erro ao carregar dados do usuário");

      // Garantir que o role seja carregado do Firestore
      await authNotifier.setUser(user);

      // Atualizar token FCM após login
      await updateFcmToken(user.uid);

      if (!mounted) return;

      // Checar role antes do redirecionamento
      final role = authNotifier.role;

      if (role == null || role.isEmpty) {
        DialogHelper.showTemporaryToast(context, 'Role do usuário não definido.');
        return;
      }

      switch (role) {
        case 'admin':
          context.go('/admin');
          break;
        case 'cliente_local':
          context.go('/local-splash');
          break;
        default:
          context.go('/menu');
      }

    } on FirebaseAuthException catch (e) {
      DialogHelper.showTemporaryToast(context, e.message ?? 'Erro no login');
    } catch (e) {
      DialogHelper.showTemporaryToast(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                      isLoading ? null : () => loginUser(context),
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
                        text: 'Não tem conta??? ',
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
