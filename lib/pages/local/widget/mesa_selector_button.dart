import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/local/provider/pedido_local_provider.dart';

class MesaSelectorButton extends StatelessWidget {
  const MesaSelectorButton({super.key});

  void _abrirSelecionarMesaSheet(BuildContext context) {
    final pedidoProvider = context.read<PedidoLocalProvider>();
    String? mesaSelecionada = pedidoProvider.numeroMesa;
    int? posicaoSelecionada = pedidoProvider.posicaoMesa;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          final List<String> mesas = List.generate(21, (i) => '${i + 1}');
          const double mesaSize = 60;
          const double cadeiraSize = 28;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'Selecione sua Mesa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: mesas.map((mesa) {
                      final isSelected = mesaSelecionada == mesa;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            mesaSelecionada = mesa;
                            posicaoSelecionada = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: mesaSize,
                          height: mesaSize,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.brown[400]
                                : Colors.brown[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                                : [],
                            border: Border.all(
                              color: isSelected
                                  ? Colors.brown.shade700
                                  : Colors.brown.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              mesa,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.brown[800],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Posições P1 / P2
                  if (mesaSelecionada != null)
                    Column(
                      children: [
                        const Text(
                          'Selecione a Posição',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: mesaSize,
                              height: mesaSize,
                              decoration: BoxDecoration(
                                color: Colors.brown[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Mesa $mesaSelecionada',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -cadeiraSize / 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => posicaoSelecionada = 0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: cadeiraSize,
                                  height: cadeiraSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: posicaoSelecionada == 0
                                        ? Colors.brown[400]
                                        : Colors.brown[100],
                                    border: Border.all(
                                      color: posicaoSelecionada == 0
                                          ? Colors.brown.shade700
                                          : Colors.brown.shade300,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'P1',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -cadeiraSize / 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => posicaoSelecionada = 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: cadeiraSize,
                                  height: cadeiraSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: posicaoSelecionada == 1
                                        ? Colors.brown[400]
                                        : Colors.brown[100],
                                    border: Border.all(
                                      color: posicaoSelecionada == 1
                                          ? Colors.brown.shade700
                                          : Colors.brown.shade300,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'P2',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Botão Confirmar
                  ElevatedButton.icon(
                    onPressed: mesaSelecionada == null ||
                        posicaoSelecionada == null
                        ? null
                        : () {
                      pedidoProvider.definirMesa(
                        mesaSelecionada!,
                        posicaoSelecionada!,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.brown[600],
                          content: Text(
                            'Mesa $mesaSelecionada (P${posicaoSelecionada! + 1}) selecionada!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[600],
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = context.watch<PedidoLocalProvider>();
    final mesa = pedido.numeroMesa;
    final pos = pedido.posicaoMesa;

    return GestureDetector(
      onTap: () => _abrirSelecionarMesaSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: mesa != null ? Colors.green[600] : Colors.orange[600],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_bar, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              mesa != null
                  ? 'Mesa $mesa • P${(pos ?? 0) + 1}'
                  : 'Selecionar Mesa',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
