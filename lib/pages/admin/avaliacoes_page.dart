// Código completo com clique no card abrindo detalhes com nome, telefone,
// itens do pedido e número do pedido.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AvaliacoesPage extends StatefulWidget {
  const AvaliacoesPage({super.key});

  @override
  State<AvaliacoesPage> createState() => _AvaliacoesPageState();
}

class _AvaliacoesPageState extends State<AvaliacoesPage> {
  String filtro = "todos";
  Color get primary => Colors.green.shade700;

  DateTime get inicioHoje {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  DateTime get inicioSemana {
    final hoje = DateTime.now();
    return hoje.subtract(Duration(days: hoje.weekday - 1));
  }

  Stream<QuerySnapshot> _queryAvaliacoes() {
    final ref = FirebaseFirestore.instance
        .collection("avaliacoes")
        .orderBy("dataAvaliacao", descending: true);

    if (filtro == "hoje") {
      return ref.where("dataAvaliacao", isGreaterThanOrEqualTo: inicioHoje).snapshots();
    }
    if (filtro == "semana") {
      return ref.where("dataAvaliacao", isGreaterThanOrEqualTo: inicioSemana).snapshots();
    }
    return ref.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primary,
        title: const Text("Relatório de Avaliações"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildHeaderDashboard(),
          _buildFiltroChips(),
          const Divider(height: 1),
          Expanded(child: _buildListaAvaliacoes()),
        ],
      ),
    );
  }

  Widget _buildHeaderDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _queryAvaliacoes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Center(
                child: Text("Nenhuma avaliação disponível.", style: TextStyle(fontSize: 16)),
              ),
            ),
          );
        }

        double soma = 0;
        for (var d in docs) {
          soma += (d["nota"] as num).toDouble();
        }
        final media = soma / docs.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 3))],
            ),
            child: Column(
              children: [
                Text("Média Geral",
                    style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 8),
                Text("${media.toStringAsFixed(1)} ⭐",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text("${docs.length} avaliações coletadas",
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltroChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _chipFiltro("Hoje", "hoje"),
          const SizedBox(width: 8),
          _chipFiltro("Semana", "semana"),
          const SizedBox(width: 8),
          _chipFiltro("Todos", "todos"),
        ],
      ),
    );
  }

  Widget _chipFiltro(String titulo, String valor) {
    final ativo = filtro == valor;
    return ChoiceChip(
      label: Text(
        titulo,
        style: TextStyle(color: ativo ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
      ),
      selected: ativo,
      selectedColor: primary,
      backgroundColor: Colors.grey.shade300,
      onSelected: (_) => setState(() => filtro = valor),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    );
  }

  Widget _buildListaAvaliacoes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _queryAvaliacoes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Nada por aqui...", style: TextStyle(fontSize: 16)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final nota = data["nota"] ?? 0;
            final comentario = data["comentario"] ?? "";
            final pedidoId = data["pedidoId"] ?? "";
            final userId = data["userId"];
            final dataAvaliacao = (data["dataAvaliacao"] as Timestamp).toDate();

            return GestureDetector(
              onTap: () => _abrirDetalhesAvaliacao(userId, pedidoId, nota, comentario, dataAvaliacao),
              child: _buildAvaliacaoCard(
                nota: nota,
                comentario: comentario,
                pedidoId: pedidoId,
                dataAvaliacao: dataAvaliacao,
              ),
            );
          },
        );
      },
    );
  }

  // ► ABRIR DETALHES
  Future<void> _abrirDetalhesAvaliacao(
      String userId, String pedidoId, int nota, String comentario, DateTime dataAvaliacao) async {
    final usuario = await FirebaseFirestore.instance.collection("users").doc(userId).get();

    final pedido = await FirebaseFirestore.instance.collection("pedidos").doc(pedidoId).get();

    final nome = usuario.data()?['nome'] ?? 'Sem nome';
    final telefone = usuario.data()?['telefone'] ?? 'Sem telefone';
    final numPedido = pedido.data()?['numeroPedido'] ?? 'Sem num';

    final itens = pedido.data()?['itens'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Detalhes da Avaliação",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 20),

                Text("Usuário", style: _titulo()),
                Text(nome, style: _conteudo()),
                Text(telefone, style: _conteudo()),

                const SizedBox(height: 16),
                Text("Pedido Avaliado", style: _titulo()),
                Text("ID: $numPedido", style: _conteudo()),

                const SizedBox(height: 10),
                Text("Itens do Pedido", style: _titulo()),
                ...itens.map((e) => Text("• ${e['nome']} (x${e['quantidade']})", style: _conteudo())),

                const SizedBox(height: 16),
                Text("Avaliação", style: _titulo()),
                Row(
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < nota ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                    ),
                  ),
                ),
                if (comentario.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(comentario, style: _conteudo()),
                ],

                const SizedBox(height: 16),
                Text(DateFormat("dd/MM/yyyy • HH:mm").format(dataAvaliacao), style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _titulo() => const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  TextStyle _conteudo() => const TextStyle(fontSize: 14, color: Colors.black87);

  Widget _buildAvaliacaoCard({
    required int nota,
    required String comentario,
    required String pedidoId,
    required DateTime dataAvaliacao,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
                  (i) => Icon(
                i < nota ? Icons.star_rounded : Icons.star_border_rounded,
                color: i < nota ? Colors.amber : Colors.grey.shade400,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (comentario.isNotEmpty)
            Text(comentario, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat("dd/MM/yyyy • HH:mm").format(dataAvaliacao),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}
