import 'package:flutter/material.dart';

class QuemSomosPage extends StatelessWidget {
  const QuemSomosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quem Somos")),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // para a coluna ocupar o espaço mínimo
              children: [
                Image.asset(
                  'assets/LogoPadariaVinhosBranco.png',
                  height: MediaQuery.of(context).size.height * 0.25,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Fundada com amor e dedicação, a Padaria Vinho's nasceu do desejo de oferecer mais do que pães fresquinhos. Somos uma padaria familiar que preza pela qualidade, atendimento acolhedor e produtos feitos com carinho. Desde o início, nosso compromisso é garantir que cada cliente sinta o sabor de casa em cada mordida. Trabalhamos diariamente para entregar variedade, sabor e tradição. Nossos pães são assados todos os dias com ingredientes selecionados e técnicas que respeitam o tempo e o cuidado que uma boa receita merece. Além disso, oferecemos bolos, salgados, doces, lanches e aquele cafezinho especial que já virou parte da rotina de nossos clientes. Mais do que uma padaria, somos um ponto de encontro da vizinhança, um espaço onde cada cliente é tratado com respeito, amizade e um sorriso no rosto. Acreditamos que a boa comida aproxima as pessoas — e é exatamente isso que buscamos fazer todos os dias. Seja bem-vindo à Padaria Vinho's, onde cada detalhe tem sabor de carinho.",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.justify,
                    ),
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
}
