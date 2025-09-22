import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:padariavinhos/models/pedido.dart';

class RelatorioClientesPage extends StatelessWidget {
  const RelatorioClientesPage({super.key});

  Future<Map<String, dynamic>> _buscarRelatorio() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pedidos')
        .where('status', isEqualTo: 'finalizado')
        .get();

    final Map<String, double> totais = {};
    final Map<String, User> usuarios = {};

    // Usa Future.wait para buscar usuários em paralelo
    final futures = snapshot.docs.map((doc) async {
      final pedido = Pedido.fromMap(doc.data(), doc.id);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(pedido.userId)
          .get();

      if (userDoc.exists) {
        final user = User.fromMap(userDoc.data()!);
        usuarios[pedido.userId] = user;
        totais[pedido.userId] =
            (totais[pedido.userId] ?? 0) + (pedido.totalFinal ?? 0);
      }
    }).toList();

    await Future.wait(futures);

    return {"usuarios": usuarios, "totais": totais};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatório de Clientes"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _buscarRelatorio(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              (snapshot.data!['usuarios'] as Map).isEmpty) {
            return const Center(child: Text("Nenhum dado encontrado."));
          }

          final usuarios = snapshot.data!['usuarios'] as Map<String, User>;
          final totais = snapshot.data!['totais'] as Map<String, double>;

          final lista = usuarios.entries.toList()
            ..sort((a, b) =>
                (totais[b.key] ?? 0).compareTo(totais[a.key] ?? 0));

          final totalGeral =
          totais.values.fold<double>(0, (soma, val) => soma + val);

          return Column(
            children: [
              // Cabeçalho com resumo geral
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Resumo Geral",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Faturado:",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            "R\$ ${totalGeral.toStringAsFixed(2)}",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Clientes Ativos:",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            "${usuarios.length}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ranking de Clientes",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Lista de clientes
              Expanded(
                child: ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final userId = lista[index].key;
                    final usuario = lista[index].value;
                    final total = totais[userId] ?? 0;

                    return Card(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            usuario.nome.isNotEmpty
                                ? usuario.nome[0].toUpperCase()
                                : "?",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          usuario.nome,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (usuario.email.isNotEmpty)
                              Text("Email: ${usuario.email}"),
                            if (usuario.telefone.isNotEmpty)
                              Text("Tel: ${usuario.telefone}"),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "R\$ ${total.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: index == 0
                                      ? Colors.green.shade800
                                      : Colors.black87),
                            ),
                            if (index == 0)
                              const Text(
                                "TOP 1",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
