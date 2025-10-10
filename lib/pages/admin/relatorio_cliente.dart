import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/user.dart';
import 'package:padariavinhos/models/pedido.dart';

class RelatorioClientesPage extends StatefulWidget {
  const RelatorioClientesPage({super.key});

  @override
  State<RelatorioClientesPage> createState() => _RelatorioClientesPageState();
}

class _RelatorioClientesPageState extends State<RelatorioClientesPage> {
  late Future<Map<String, dynamic>> _relatorioFuture;

  @override
  void initState() {
    super.initState();
    _relatorioFuture = _buscarRelatorio();
  }

  Future<Map<String, dynamic>> _buscarRelatorio() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('status', isEqualTo: 'finalizado')
          .get();

      final Map<String, double> totais = {};
      final Map<String, User> usuarios = {};

      // Busca todos os usuários distintos de uma vez só
      final userIds = snapshot.docs.map((e) => e['userId'] as String).toSet();

      final userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds.toList())
          .get();

      for (var doc in userDocs.docs) {
        usuarios[doc.id] = User.fromMap(doc.data());
      }

      for (var doc in snapshot.docs) {
        final pedido = Pedido.fromMap(doc.data(), doc.id);
        totais[pedido.userId] =
            (totais[pedido.userId] ?? 0) + (pedido.totalFinal ?? 0);
      }

      return {"usuarios": usuarios, "totais": totais};
    } catch (e) {
      debugPrint("Erro ao buscar relatório: $e");
      return {"usuarios": {}, "totais": {}};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Relatório de Clientes"),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.green.shade700,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _relatorioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar dados: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final usuarios = snapshot.data?['usuarios'] as Map<String, User>? ?? {};
          final totais = snapshot.data?['totais'] as Map<String, double>? ?? {};

          if (usuarios.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum dado encontrado.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final lista = usuarios.entries.toList()
            ..sort(
                  (a, b) => (totais[b.key] ?? 0).compareTo(totais[a.key] ?? 0),
            );

          final totalGeral =
          totais.values.fold<double>(0, (soma, val) => soma + val);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _relatorioFuture = _buscarRelatorio());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildResumoCard(totalGeral, usuarios.length),
                const SizedBox(height: 20),
                const Text(
                  "🏆 Ranking de Clientes",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 10),
                _buildDataTable(lista, totais),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumoCard(double totalGeral, int clientesAtivos) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Resumo Geral",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Faturado:",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  "R\$ ${totalGeral.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Clientes Ativos:",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  "$clientesAtivos",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<MapEntry<String, User>> lista, Map<String, double> totais) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          horizontalMargin: 16,
          headingRowColor:
          WidgetStateProperty.all(Colors.green.shade50.withOpacity(0.9)),
          border: TableBorder.symmetric(
              inside: const BorderSide(color: Colors.grey, width: 0.1)),
          columns: const [
            DataColumn(label: Text("Posição")),
            DataColumn(label: Text("Cliente")),
            DataColumn(label: Text("Email")),
            DataColumn(label: Text("Telefone")),
            DataColumn(label: Text("Total Comprado")),
          ],
          rows: List.generate(lista.length, (index) {
            final userId = lista[index].key;
            final usuario = lista[index].value;
            final total = totais[userId] ?? 0;
            final rankColor = _rankColor(index);

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    "#${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ),
                DataCell(Text(usuario.nome.isNotEmpty ? usuario.nome : "—")),
                DataCell(Text(usuario.email.isNotEmpty ? usuario.email : "—")),
                DataCell(
                    Text(usuario.telefone.isNotEmpty ? usuario.telefone : "—")),
                DataCell(Text(
                  "R\$ ${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight:
                    index == 0 ? FontWeight.bold : FontWeight.normal,
                    color: rankColor,
                  ),
                )),
              ],
            );
          }),
        ),
      ),
    );
  }

  Color _rankColor(int index) {
    if (index == 0) return Colors.green.shade800;
    if (index == 1) return Colors.green.shade600;
    if (index == 2) return Colors.green.shade400;
    return Colors.black87;
  }
}
