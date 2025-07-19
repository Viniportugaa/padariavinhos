import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:padariavinhos/pages/fazer_pedido_page.dart';
import 'package:padariavinhos/pages/fazer_orcamento_page.dart';
import 'package:padariavinhos/pages/sua_conta_page.dart';
import 'package:padariavinhos/pages/quem_somos_page.dart';
import 'package:padariavinhos/pages/opcoes_page.dart';
import 'package:padariavinhos/pages/login_page.dart';
import 'package:padariavinhos/pages/telainicial.dart';
import 'package:padariavinhos/pages/cadastro_produto_page.dart';
import 'package:padariavinhos/router.dart';
import 'package:go_router/go_router.dart';

class MenuInicial extends StatelessWidget {

  static route() =>
      MaterialPageRoute(
        builder: (context) => const MenuInicial(),
      );

  const MenuInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green,
              Colors.black,
              Colors.black,
              Colors.red,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Image.asset(
                      'assets/LogoPadariaVinhosBranco.png',
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.25,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botões
                  buildBotao(context, 'Faça seu pedido', Colors.green),
                  buildBotao(context, 'Faça seu orçamento', Colors.red),
                  buildBotao(context, 'Sua Conta', Colors.green),
                  buildBotao(context, 'Quem Somos', Colors.red, pequeno: true),
                  buildBotao(context, 'Opções', Colors.green, pequeno: true),
                  buildBotao(
                      context, 'Cadastrar Produto', Colors.red, pequeno: true),
                  buildBotao(context, 'SAIR', Colors.grey[850]!),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBotao(BuildContext context, String texto, Color cor,
      {bool pequeno = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: pequeno
            ? MediaQuery
            .of(context)
            .size
            .width * 0.5
            : MediaQuery
            .of(context)
            .size
            .width * 0.8,
        child: ElevatedButton(
          onPressed: () {
            if (texto == 'SAIR') {
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(
                      title: const Text('Confirmação'),
                      content: const Text('Tem certeza que deseja sair?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context); // Fecha o diálogo primeiro
                            await FirebaseAuth.instance.signOut();
                            context.go('/login'); // Navega para a tela de login corretamente
                          },
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
              );
            }
            else {
              switch (texto) {
                case 'Faça seu pedido':
                  context.push ('/pedido');
                  break;
                case 'Faça seu orçamento':
                  context.push('/orcamento');
                  break;
                case 'Sua Conta':
                  context.push('/conta');
                  break;
                case 'Quem Somos':
                  context.push('/quem-somos');
                  break;
                case 'Opções':
                  context.push('/opcoes');
                  break;
                case 'Cadastrar Produto':
                  context.push('/cadastro-produto');
                  break;
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 16),
          ),

        ),
      ),
    );
  }
}