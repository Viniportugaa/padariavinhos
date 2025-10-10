import 'package:flutter/material.dart';

class PoliticaPrivacidadePage extends StatelessWidget {
  const PoliticaPrivacidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Política de Privacidade",
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
              Color(0xFF006400), // Verde escuro
              Colors.black,
              Color(0xFF8B0000), // Vinho
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight + 40),
                // Logo com animação
                Hero(
                  tag: 'logoPadaria',
                  child: Image.asset(
                    'assets/LogoPadariaVinhosBranco.png',
                    height: MediaQuery.of(context).size.height * 0.20,
                  ),
                ),
                const SizedBox(height: 24),
                // Cartão translúcido com rolagem
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "🛡️ Política de Privacidade – Padaria Vinho’s",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              "Última atualização: 11 de outubro de 2025",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "A Padaria Vinho’s valoriza a privacidade e a proteção dos dados pessoais de seus usuários. Esta Política de Privacidade descreve como coletamos, utilizamos, armazenamos, tratamos e protegemos suas informações pessoais, em conformidade com a Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018 – LGPD).",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          SizedBox(height: 24),
                          _SectionTitle("1. Dados pessoais coletados"),
                          _SectionText(
                            "Durante o cadastro e o uso do aplicativo, poderemos coletar os seguintes dados:\n\n"
                                "• Nome completo;\n"
                                "• Endereço completo (rua, número, complemento, bairro, cidade e CEP);\n"
                                "• Telefone;\n"
                                "• E-mail;\n"
                                "• Senha de acesso (armazenada de forma criptografada);\n"
                                "• Dados de localização (quando necessário para cálculo de entrega ou exibição de lojas próximas).",
                          ),
                          _SectionText(
                            "Essas informações são necessárias para o funcionamento adequado do aplicativo, entrega de pedidos e autenticação segura do usuário.",
                          ),
                          _SectionTitle("2. Finalidade do tratamento dos dados"),
                          _SectionText(
                            "Os dados pessoais coletados são utilizados exclusivamente para:\n\n"
                                "• Identificação do usuário no sistema;\n"
                                "• Processamento, acompanhamento e entrega de pedidos;\n"
                                "• Comunicação sobre o status do pedido;\n"
                                "• Cálculo de frete e estimativa de tempo de entrega;\n"
                                "• Garantia de acesso seguro à conta e suporte técnico.\n\n"
                                "A Padaria Vinho’s não compartilha, vende ou utiliza dados pessoais para fins comerciais, publicitários ou não autorizados.",
                          ),
                          _SectionTitle("3. Base legal para o tratamento"),
                          _SectionText(
                            "O tratamento dos dados pessoais ocorre com base nas seguintes hipóteses legais previstas na LGPD:\n\n"
                                "• Execução de contrato;\n"
                                "• Cumprimento de obrigação legal;\n"
                                "• Consentimento do titular.",
                          ),
                          _SectionTitle("4. Armazenamento e segurança das informações"),
                          _SectionText(
                            "A Padaria Vinho’s adota medidas técnicas e organizacionais adequadas para proteger seus dados pessoais contra acessos não autorizados, destruição, perda, alteração ou divulgação indevida.\n\n"
                                "• Armazenamento seguro com criptografia e autenticação;\n"
                                "• Senhas criptografadas;\n"
                                "• Controle de acesso restrito;\n"
                                "• Monitoramento e auditorias periódicas.",
                          ),
                          _SectionTitle("5. Direitos do titular dos dados"),
                          _SectionText(
                            "De acordo com a LGPD, você tem direito de:\n\n"
                                "• Confirmar o tratamento de seus dados pessoais;\n"
                                "• Corrigir ou atualizar seus dados;\n"
                                "• Solicitar exclusão da conta;\n"
                                "• Revogar consentimento;\n"
                                "• Solicitar portabilidade dos dados.\n\n"
                                "Essas solicitações podem ser feitas diretamente pelo aplicativo ou pelo contato do Encarregado (DPO).",
                          ),
                          _SectionTitle("6. Retenção e exclusão dos dados"),
                          _SectionText(
                            "Os dados pessoais serão mantidos apenas pelo tempo necessário para cumprir as finalidades informadas nesta Política. Após esse período, as informações serão excluídas de forma segura.",
                          ),
                          _SectionTitle("7. Compartilhamento de dados"),
                          _SectionText(
                            "A Padaria Vinho’s não compartilha dados pessoais com terceiros, exceto quando necessário para cumprir obrigações legais ou para operação segura do app (como hospedagem ou pagamento).",
                          ),
                          _SectionTitle("8. Consentimento e alterações desta Política"),
                          _SectionText(
                            "Ao se cadastrar e utilizar o aplicativo, o usuário reconhece e concorda com os termos desta Política. Atualizações serão informadas por meio do aplicativo e/ou e-mail cadastrado.",
                          ),
                          _SectionTitle("9. Encarregado de Proteção de Dados (DPO)"),
                          _SectionText(
                            "E-mail: padariavinhos@gmail.com\nResponsável: Encarregado de Proteção de Dados – Padaria Vinho’s",
                          ),
                          _SectionTitle("10. Foro e disposições finais"),
                          _SectionText(
                            "Esta Política é regida pelas leis da República Federativa do Brasil. Controvérsias serão solucionadas no foro da comarca da sede da Padaria Vinho’s, salvo disposições legais em contrário.",
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              "📜 Padaria Vinho’s – Compromisso com a transparência, segurança e privacidade dos seus dados.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
      ),
    );
  }
}

// ====== Widgets auxiliares reutilizáveis ======
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.6,
      ),
      textAlign: TextAlign.justify,
    );
  }
}
