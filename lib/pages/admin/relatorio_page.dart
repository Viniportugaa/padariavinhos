import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/item_carrinho.dart';

enum PeriodoFiltro { hoje, semana, mes, todos }

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  PeriodoFiltro _filtroSelecionado = PeriodoFiltro.hoje;

  List<Pedido> _filtrarPedidos(List<Pedido> pedidos) {
    final agora = DateTime.now();
    switch (_filtroSelecionado) {
      case PeriodoFiltro.hoje:
        return pedidos.where((p) =>
        p.data.year == agora.year &&
            p.data.month == agora.month &&
            p.data.day == agora.day).toList();
      case PeriodoFiltro.semana:
        final inicioSemana = agora.subtract(Duration(days: agora.weekday - 1));
        final fimSemana = inicioSemana.add(const Duration(days: 7));
        return pedidos
            .where((p) => p.data.isAfter(inicioSemana) && p.data.isBefore(fimSemana))
            .toList();
      case PeriodoFiltro.mes:
        return pedidos
            .where((p) => p.data.year == agora.year && p.data.month == agora.month)
            .toList();
      case PeriodoFiltro.todos:
        return pedidos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Relatórios de Vendas'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        elevation: 3,
      ),
      body: Column(
        children: [
          _buildFiltro(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum pedido encontrado."));
                }

                final pedidos = snapshot.data!.docs
                    .map((doc) => Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                final pedidosFiltrados = _filtrarPedidos(pedidos);
                if (pedidosFiltrados.isEmpty) {
                  return const Center(child: Text("Nenhum pedido neste período."));
                }

                final produtosVendidos = _getProdutosMaisVendidos(pedidosFiltrados);
                final acompanhamentos = _getAcompanhamentosMaisEscolhidos(pedidosFiltrados);
                final pedidosPorHora = _getPedidosPorHora(pedidosFiltrados);
                final faturamento = _getFaturamento(pedidosFiltrados);
                final ticketMedio = faturamento / pedidosFiltrados.length;

                return AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 400),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildResumoGeralCard(
                            faturamento, pedidosFiltrados.length, ticketMedio),

                        const SizedBox(height: 20),
                        _buildSectionTitle('📦 Produtos Mais Vendidos'),
                        _buildBarChart(produtosVendidos, color: Colors.blueAccent),

                        const SizedBox(height: 24),
                        _buildSectionTitle('🍞 Acompanhamentos Mais Escolhidos'),
                        _buildBarChart(acompanhamentos, color: Colors.orangeAccent),

                        const SizedBox(height: 24),
                        _buildSectionTitle('⏰ Horários com Pico de Pedidos'),
                        _buildLineChart(pedidosPorHora),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ===================== UI COMPONENTS =====================
  Widget _buildFiltro() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SegmentedButton<PeriodoFiltro>(
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
        segments: const [
          ButtonSegment(value: PeriodoFiltro.hoje, label: Text('Hoje')),
          ButtonSegment(value: PeriodoFiltro.semana, label: Text('Semana')),
          ButtonSegment(value: PeriodoFiltro.mes, label: Text('Mês')),
          ButtonSegment(value: PeriodoFiltro.todos, label: Text('Todos')),
        ],
        selected: {_filtroSelecionado},
        onSelectionChanged: (v) => setState(() => _filtroSelecionado = v.first),
      ),
    );
  }

  Widget _buildResumoGeralCard(double faturamento, int pedidos, double ticket) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade700,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResumoItem('Faturamento', 'R\$ ${faturamento.toStringAsFixed(2)}'),
            _buildResumoItem('Pedidos', '$pedidos'),
            _buildResumoItem('Ticket Médio', 'R\$ ${ticket.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(String titulo, String valor) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBarChart(Map<String, int> data,
      {Color color = Colors.blueAccent}) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          barGroups: entries
              .take(6)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          )
              .toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(entries[i].key,
                        style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<int, int> data) {
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final spots = entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                  colors: [Colors.deepOrange, Colors.orangeAccent]),
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text("${v.toInt()}h",
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ===================== LÓGICA =====================
  Map<String, int> _getProdutosMaisVendidos(List<Pedido> pedidos) {
    final Map<String, int> count = {};
    for (var pedido in pedidos) {
      for (var item in pedido.itens) {
        final nome = item.produto.nome;
        count[nome] = (count[nome] ?? 0) + item.quantidade.toInt();
      }
    }
    return count;
  }

  Map<String, int> _getAcompanhamentosMaisEscolhidos(List<Pedido> pedidos) {
    final Map<String, int> count = {};
    for (var pedido in pedidos) {
      for (var item in pedido.itens) {
        for (var acomp in item.acompanhamentos ?? []) {
          count[acomp.nome] = (count[acomp.nome] ?? 0) + 1;
        }
      }
    }
    return count;
  }

  Map<int, int> _getPedidosPorHora(List<Pedido> pedidos) {
    final Map<int, int> count = {};
    for (var pedido in pedidos) {
      final hour = pedido.data.hour;
      count[hour] = (count[hour] ?? 0) + 1;
    }
    return count;
  }

  double _getFaturamento(List<Pedido> pedidos) {
    return pedidos.fold<double>(
        0.0, (anterior, p) => anterior + (p.totalFinal ?? 0));
  }
}
