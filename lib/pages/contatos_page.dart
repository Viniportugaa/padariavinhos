import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContatoPage extends StatelessWidget {
  const ContatoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Contato & Dúvidas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF006400),
              Colors.black,
              Color(0xFF8B0000),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: kToolbarHeight + 40),

              // Título
              const Text(
                'Fale Conosco',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Cartões em estilo translúcido igual ao QuemSomosPage
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: const [
                        _ContatoCard(
                          icon: Icons.email,
                          title: 'E-mail',
                          value: 'padariavinhos@gmail.com',
                          type: ContatoType.email,
                        ),
                        _ContatoCard(
                          icon: Icons.chat,
                          title: 'WhatsApp',
                          value: '+55 11 98187-2062',
                          type: ContatoType.whatsapp,
                        ),
                        _ContatoCard(
                          icon: Icons.phone,
                          title: 'Telefone 1',
                          value: '+55 11 3885-8953',
                          type: ContatoType.telefone,
                        ),
                        _ContatoCard(
                          icon: Icons.phone_in_talk,
                          title: 'Telefone 2',
                          value: '+55 11 3057-2820',
                          type: ContatoType.telefone,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Estamos aqui para ajudar! Tire dúvidas sobre produtos, pedidos ou suporte geral.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "© ${DateTime.now().year} Padaria Vinho's",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ContatoType { email, whatsapp, telefone }

class _ContatoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ContatoType type;

  const _ContatoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.type,
  });

  Future<void> _openAction() async {
    Uri uri;

    switch (type) {
      case ContatoType.email:
        uri = Uri(
          scheme: 'mailto',
          path: value,
          query: 'subject=Contato via App&body=Olá, tenho uma dúvida:',
        );
        break;

      case ContatoType.whatsapp:
        final number = value.replaceAll(RegExp(r'[^0-9]'), '');
        uri = Uri.parse('https://wa.me/$number');
        break;

      case ContatoType.telefone:
        final number = value.replaceAll(RegExp(r'[^0-9]'), '');
        uri = Uri(scheme: 'tel', path: number);
        break;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir: $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.help_outline, color: Colors.redAccent, size: 26),
                  SizedBox(width: 10),
                  Text('Confirmar ação', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'Deseja realmente abrir "$title"?',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _openAction();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
