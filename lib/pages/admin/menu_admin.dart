import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/pages/menu/menu_button.dart';
import 'package:padariavinhos/widgets/auth_panel.dart';

class MenuAdmin extends StatelessWidget {
  const MenuAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final bool isTablet = largura > 10000;

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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// LOGO
                Hero(
                  tag: 'logo-admin',
                  child: Image.asset(
                    'assets/LogoPadariaVinhosBranco.png',
                    height: largura * 0.18,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                /// BOTÃO PRINCIPAL
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => context.go('/lista'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long, size: 30, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Ver Pedidos Ativos',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                /// BLOCO COM BACKGROUND SUTIL
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.07),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      /// TÍTULO DO MENU
                      Text(
                        'Ferramentas Administrativas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// GRID MELHOR ORGANIZADO
                      GridView.count(
                        crossAxisCount: isTablet ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.00,
                        children: [
                          buildMenuBotao(context, 'Produtos', Icons.shopping_basket,
                              Colors.blueAccent, '/listaproduto',
                              largura: largura),

                          buildMenuBotao(context, 'Acomp', Icons.fastfood,
                              Colors.teal, '/acomp',
                              largura: largura),

                          buildMenuBotao(context, 'New Prod.', Icons.add_box,
                              Colors.orange, '/cadastro-produto',
                              largura: largura),

                          buildMenuBotao(context, 'Banners', Icons.image,
                              Colors.purple, '/banneradmin',
                              largura: largura),

                          buildMenuBotao(context, 'Avaliações', Icons.star,
                              Colors.yellow, '/avaliacoesadmin',
                              largura: largura),

                          buildMenuBotao(context, 'Local ADM', Icons.store,
                              Colors.indigo, '/local',
                              largura: largura),

                          buildMenuBotao(context, 'Local User',
                              Icons.store_mall_directory, Colors.pinkAccent, '/local2',
                              largura: largura),

                          buildMenuBotao(context, 'Cupons', Icons.monetization_on,
                              Colors.amber, '/cupomadmin',
                              largura: largura),

                          buildMenuBotao(context, 'Relatórios', Icons.bar_chart,
                              Colors.amber, '/relatorio',
                              largura: largura),

                          buildMenuBotao(context, 'Horário', Icons.access_time,
                              Colors.deepOrange, '/config-abertura',
                              largura: largura),

                          /// SAIR
                          buildMenuBotao(context, 'Sair', Icons.logout, Colors.grey,
                              null,
                              isLogout: true,
                              largura: largura),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),



                /// RODAPÉ
                Text(
                  '© 2025 Padaria & Vinhos • Painel do Administrador',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
