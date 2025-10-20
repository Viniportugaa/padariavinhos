import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/menu/menu_button.dart';
import 'package:padariavinhos/widgets/auth_panel.dart';

class MenuAdmin extends StatelessWidget {
  const MenuAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isTablet = largura > 600;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 LOGO CENTRALIZADA
                Hero(
                  tag: 'logo-admin',
                  child: Image.asset(
                    'assets/LogoPadariaVinhosBranco.png',
                    height: largura * 0.15,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Botão Principal: Ver Pedidos
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                    ),
                    icon: const Icon(Icons.receipt_long, size: 28, color: Colors.white),
                    label: const Text(
                      'Ver Pedidos Ativos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () => context.go('/lista'),
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 GRID ADMINISTRATIVO (responsivo)
                GridView.count(
                  crossAxisCount: isTablet ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  children: [
                    buildMenuBotao(context, 'Produtos', Icons.shopping_basket,
                        Colors.blueAccent, '/listaproduto',
                        largura: largura),
                    buildMenuBotao(context, 'Acompanhamentos', Icons.fastfood,
                        Colors.teal, '/acomp',
                        largura: largura),
                    buildMenuBotao(context, 'Novo Produto', Icons.add_box,
                        Colors.orange, '/cadastro-produto',
                        largura: largura),
                    buildMenuBotao(context, 'Banners', Icons.image,
                        Colors.purple, '/banneradmin',
                        largura: largura),
                    buildMenuBotao(context, 'Local Admin Painel', Icons.store, Colors.indigo,
                        '/local', largura: largura),
                    buildMenuBotao(context, 'Local Fazer Pedido'  ,
                        Icons.store_mall_directory, Colors.pinkAccent, '/local2',
                        largura: largura),
                    buildMenuBotao(context, 'Cupons', Icons.monetization_on,
                        Colors.amber, '/cupomadmin',
                        largura: largura),
                    buildMenuBotao(context, 'Categorias', Icons.category,
                        Colors.indigoAccent, '/categoriadmin',
                        largura: largura),
                    buildMenuBotao(context, 'Relatórios', Icons.bar_chart,
                        Colors.amber.shade700, '/relatorio',
                        largura: largura),
                    buildMenuBotao(context, 'Combos', Icons.layers, Colors.red,
                        '/comboadmin', largura: largura),
                    buildMenuBotao(context, 'Horário', Icons.access_time,
                        Colors.deepOrange, '/config-abertura',
                        largura: largura),

                    // 🔹 Botão de Sair
                    buildMenuBotao(context, 'Sair', Icons.logout, Colors.grey,
                        null,
                        isLogout: true, largura: largura),
                  ],
                ),

                const SizedBox(height: 30),

                // 🔹 Painel de autenticação e status
                Card(
                  color: Colors.white.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: AuthStatusPanel(),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Rodapé
                Text(
                  '© 2025 Padaria & Vinhos • Painel do Administrador',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
