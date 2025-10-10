import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/widgets/auth_panel.dart';

class MenuAdmin extends StatelessWidget {
  const MenuAdmin({super.key});

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
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const SizedBox(height: 16),

              // Logo
              Center(
                child: Image.asset(
                  'assets/LogoPadariaVinhosBranco.png',
                  height: MediaQuery.of(context).size.width * 0.12,
                ),
              ),
              const SizedBox(height: 24),

              // Botão especial "Ver Pedidos"
              _buildCardDestaque(
                context,
                _MenuItem(
                  'Ver Pedidos',
                  Icons.receipt_long,
                  Colors.green,
                  '/lista',
                  corCard: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 16),
              // Agora cada card declarado manualmente
// Substitui o Wrap pelo GridView
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, // sempre 2 por linha
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1, // quadrado, pode ajustar
                children: [
                  _buildCard(
                    context,
                    _MenuItem('Produtos', Icons.shopping_basket, Colors.blue, '/listaproduto',
                        corCard: Colors.blueAccent),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Acompanhamentos', Icons.fastfood, Colors.teal, '/acomp',
                        corCard: Colors.teal),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Novo Produto', Icons.add_box, Colors.orange, '/cadastro-produto',
                        corCard: Colors.orangeAccent),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Banners', Icons.image, Colors.purple, '/banneradmin',
                        corCard: Colors.purpleAccent),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('LOCAL1', Icons.image, Colors.purple, '/local',
                        corCard: Colors.purpleAccent),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('LOCAL2', Icons.image, Colors.purple, '/local2',
                        corCard: Colors.purpleAccent),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Cupons', Icons.monetization_on, Colors.blueAccent, '/cupomadmin',
                        corCard: Colors.purpleAccent),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Categorias', Icons.category, Colors.indigo, '/categoriadmin',
                        corCard: Colors.indigo),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Relatórios', Icons.bar_chart, Colors.amber, '/relatorio',
                        corCard: Colors.amber),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Combos', Icons.layers, Colors.red, '/comboadmin',
                        corCard: Colors.red),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Horário', Icons.access_time, Colors.deepOrange, '/config-abertura',
                        corCard: Colors.deepOrange),
                  ),
                  _buildCard(
                    context,
                    _MenuItem('Sair', Icons.logout, Colors.grey, null,
                        isLogout: true, corCard: Colors.black87),
                  ),
                ],
              ),


              const SizedBox(height: 24),
              const AuthStatusPanel(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Card normal
  Widget _buildCard(BuildContext context, _MenuItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        if (item.isLogout) {
          _confirmarLogout(context);
        } else if (item.rota != null) {
          context.push(item.rota!);
        }
      },
      child: SizedBox(
        width: 120,
        height: 120,
        child: Card(
          elevation: 4,
          color: item.corCard,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconeComBorda(item, radius: 20, size: 22),
                const SizedBox(height: 8),
                Text(
                  item.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // letras brancas
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      )
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card especial "Ver Pedidos"
  Widget _buildCardDestaque(BuildContext context, _MenuItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (item.rota != null) context.push(item.rota!);
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconeComBorda(item, radius: 30, size: 30),
              const SizedBox(width: 16),
              const Text(
                'Ver Pedidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Ícone com borda
  Widget _iconeComBorda(_MenuItem item,
      {double radius = 20, double size = 22}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: item.cor.withOpacity(0.15),
        radius: radius,
        child: Icon(item.icone, size: size, color: Colors.white),
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthNotifier>(context, listen: false);
              await auth.logout();
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  context.replace('/splash');
                }
              });
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String titulo;
  final IconData icone;
  final Color cor;
  final String? rota;
  final bool isLogout;
  final Color corCard;

  _MenuItem(this.titulo, this.icone, this.cor, this.rota,
      {this.isLogout = false, this.corCard = Colors.white60});
}
