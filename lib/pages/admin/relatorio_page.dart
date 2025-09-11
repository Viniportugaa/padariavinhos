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

  /// ================= FILTRAGEM =================
  List<Pedido> _filtrarPedidos(List<Pedido> pedidos) {
    final agora = DateTime.now();
    switch (_filtroSelecionado) {
      case PeriodoFiltro.hoje:
        return pedidos
            .where((p) =>
        p.data.year == agora.year &&
            p.data.month == agora.month &&
            p.data.day == agora.day)
            .toList();
      case PeriodoFiltro.semana:
        final inicioSemana = agora.subtract(Duration(days: agora.weekday - 1));
        return pedidos
            .where((p) =>
        p.data.isAfter(inicioSemana) &&
            p.data.isBefore(inicioSemana.add(const Duration(days: 7))))
            .toList();
      case PeriodoFiltro.mes:
        return pedidos
            .where(
                (p) => p.data.year == agora.year && p.data.month == agora.month)
            .toList();
      case PeriodoFiltro.todos:
        return pedidos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFiltro(),

          /// 🔹 StreamBuilder para buscar os pedidos do Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum pedido encontrado"));
                }

                final pedidos = snapshot.data!.docs
                    .map((doc) =>
                    Pedido.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                final pedidosFiltrados = _filtrarPedidos(pedidos);

                final produtosVendidos =
                _getProdutosMaisVendidos(pedidosFiltrados);
                final acompanhamentosMaisEscolhidos =
                _getAcompanhamentosMaisEscolhidos(pedidosFiltrados);
                final pedidosPorHora = _getPedidosPorHora(pedidosFiltrados);
                final ticketMedio = _getTicketMedio(pedidosFiltrados);

                return AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildSectionTitle('📊 Produtos Mais Vendidos'),
                        _buildBarChart(produtosVendidos, topCount: 4),

                        const SizedBox(height: 24),
                        _buildSectionTitle('🥗 Acompanhamentos Mais Escolhidos'),
                        _buildBarChart(acompanhamentosMaisEscolhidos,
                            topCount: 4),

                        const SizedBox(height: 24),
                        _buildSectionTitle('⏰ Horários com Pico de Pedidos'),
                        _buildLineChart(pedidosPorHora, topCount: 4),

                        const SizedBox(height: 24),
                        _buildSectionTitle('💰 Ticket Médio'),
                        _buildTicketMedioCard(ticketMedio),
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

  /// ================= FILTRO =================
  Widget _buildFiltro() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SegmentedButton<PeriodoFiltro>(
        segments: const [
          ButtonSegment(value: PeriodoFiltro.hoje, label: Text('Hoje')),
          ButtonSegment(value: PeriodoFiltro.semana, label: Text('Semana')),
          ButtonSegment(value: PeriodoFiltro.mes, label: Text('Mês')),
          ButtonSegment(value: PeriodoFiltro.todos, label: Text('Todos')),
        ],
        selected: {_filtroSelecionado},
        onSelectionChanged: (v) =>
            setState(() => _filtroSelecionado = v.first),
      ),
    );
  }

  /// ================= SEÇÕES =================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  /// ================= CHARTS =================
  Widget _buildBarChart(Map<String, int> data, {int topCount = 4}) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StatefulBuilder(
      builder: (context, setState) {
        bool expand = false;
        List<MapEntry<String, int>> getEntries() =>
            expand ? entries : entries.take(topCount).toList();

        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (getEntries()
                        .map((e) => e.value)
                        .fold(0, (a, b) => a > b ? a : b) *
                        1.2)
                        .toDouble(),
                    barGroups: List.generate(getEntries().length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: getEntries()[i].value.toDouble(),
                            width: 20,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent, Colors.lightBlueAccent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, interval: 1),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= getEntries().length) {
                              return const SizedBox.shrink();
                            }
                            return Text(getEntries()[index].key,
                                style: const TextStyle(fontSize: 12));
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (entries.length > topCount)
              TextButton(
                onPressed: () => setState(() => expand = !expand),
                child: Text(expand ? 'Ver menos' : 'Ver mais'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLineChart(Map<int, int> data, {int topCount = 4}) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StatefulBuilder(
      builder: (context, setState) {
        bool expand = false;
        List<MapEntry<int, int>> getEntries() =>
            expand ? sorted : sorted.take(topCount).toList();

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: getEntries()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                          e.key.toDouble(), e.value.value.toDouble()))
                          .toList(),
                      isCurved: true,
                      barWidth: 3,
                      gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.deepOrangeAccent]),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= getEntries().length) {
                            return const SizedBox.shrink();
                          }
                          return Text('${getEntries()[index].key}h',
                              style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                  ),
                ),
              ),
            ),
            if (sorted.length > topCount)
              TextButton(
                onPressed: () => setState(() => expand = !expand),
                child: Text(expand ? 'Ver menos' : 'Ver mais'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTicketMedioCard(double ticketMedio) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade400,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Ticket Médio',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${ticketMedio.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= LÓGICA =================
  Map<String, int> _getProdutosMaisVendidos(List<Pedido> pedidos) {
    final Map<String, int> count = {};
    for (var pedido in pedidos) {
      for (var item in pedido.itens) {
        count[item.produto.nome] =
            (count[item.produto.nome] ?? 0) + item.quantidade.toInt();
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
        if (item.acompanhamentosPorProduto != null) {
          for (var lista in item.acompanhamentosPorProduto!.values) {
            for (var acomp in lista) {
              count[acomp.nome] = (count[acomp.nome] ?? 0) + 1;
            }
          }
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

  double _getTicketMedio(List<Pedido> pedidos) {
    if (pedidos.isEmpty) return 0.0;

    final soma = pedidos.fold<double>(
      0.0,
          (anterior, pedido) =>
      anterior + (pedido.totalFinal ?? pedido.totalComFrete),
    );

    return soma / pedidos.length;
  }
}
