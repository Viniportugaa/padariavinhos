import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controller/conclusao_pedido_controller.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'glass_card.dart';

class PagamentoSelector extends StatelessWidget {
  final ConclusaoPedidoController controller;
  final CarrinhoProvider carrinho;

  const PagamentoSelector({
    super.key,
    required this.controller,
    required this.carrinho,
  });

  @override
  Widget build(BuildContext context) {
    final totalComFrete = carrinho.total + controller.frete;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Forma de Pagamento (Feito no local):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              DropdownButton<String>(
                value: controller.formaPagamento,
                items: controller.formasPagamento
                    .map(
                      (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.formaPagamento = value;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🔹 Campo de valor pago (aparece apenas se for "Dinheiro")
          if (controller.formaPagamento == 'Dinheiro') ...[
            TextField(
              decoration: InputDecoration(
                labelText: 'Valor pago (R\$)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (valor) {
                final pago = double.tryParse(valor.replaceAll(',', '.')) ?? 0;
                controller.definirValorPago(pago, totalComFrete);
              },
            ),
            const SizedBox(height: 8),

            // 🔹 Exibe o troco calculado
            AnimatedOpacity(
              opacity: (controller.troco != null) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: controller.troco != null
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  controller.valorPago == null || controller.valorPago == 0
                      ? 'Informe o valor pago para calcular o troco.'
                      : controller.valorPago! < totalComFrete
                      ? 'Valor insuficiente para cobrir o total.'
                      : 'Troco: R\$ ${controller.troco!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: controller.valorPago != null &&
                        controller.valorPago! < totalComFrete
                        ? Colors.redAccent
                        : Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
