import 'package:flutter/material.dart';

class QuemSomosPage extends StatelessWidget {
  const QuemSomosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Quem Somos",
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
              Color(0xFF006400), // Verde escuro elegante
              Colors.black,
              Color(0xFF8B0000), // Vermelho vinho
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight + 40),
                // Logo com leve animação
                Hero(
                  tag: 'logoPadaria',
                  child: Image.asset(
                    'assets/LogoPadariaVinhosBranco.png',
                    height: MediaQuery.of(context).size.height * 0.22,
                  ),
                ),
                const SizedBox(height: 24),
                // Cartão translúcido para o texto
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Text(
                            "Nossa História",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Fundada com amor e dedicação, a Padaria Vinho's nasceu do desejo de oferecer mais do que pães fresquinhos. Somos uma padaria familiar que preza pela qualidade, atendimento acolhedor e produtos feitos com carinho.\n\nDesde o início, nosso compromisso é garantir que cada cliente sinta o sabor de casa em cada mordida. Trabalhamos diariamente para entregar variedade, sabor e tradição.\n\nNossos pães são assados todos os dias com ingredientes selecionados e técnicas que respeitam o tempo e o cuidado que uma boa receita merece. Além disso, oferecemos bolos, salgados, doces, lanches e aquele cafezinho especial que já virou parte da rotina de nossos clientes.\n\nMais do que uma padaria, somos um ponto de encontro da vizinhança — um espaço onde cada cliente é tratado com respeito, amizade e um sorriso no rosto. Acreditamos que a boa comida aproxima as pessoas — e é exatamente isso que buscamos fazer todos os dias.\n\nSeja bem-vindo à Padaria Vinho's, onde cada detalhe tem sabor de carinho.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Rodapé sutil
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
      ),
    );
  }
}
