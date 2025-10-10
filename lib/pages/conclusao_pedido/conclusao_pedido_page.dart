import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/pages/conclusao_pedido/controller/conclusao_pedido_controller.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/carrinho_item_card.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/endereco_card.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/pagamento_selector.dart';
import 'package:padariavinhos/helpers/preco_helper.dart';
import 'package:padariavinhos/helpers/pedido_validador.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/pedido_minimo_widget.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/cupom_input.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/pages/conclusao_pedido/widgets/sugestoes_tab.dart';
import 'package:padariavinhos/helpers/aberto_conclusao_check.dart';

class ConclusaoPedidoPage extends StatelessWidget {
  const ConclusaoPedidoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConclusaoPedidoController()
        ..carregarAcompanhamentos()
        ..carregarSugestoes(),
      child: const _ConclusaoPedidoPageBody(),
    );
  }
}

class _ConclusaoPedidoPageBody extends StatelessWidget {
  const _ConclusaoPedidoPageBody();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ConclusaoPedidoController>(context);
    final carrinho = Provider.of<CarrinhoProvider>(context);
    final authNotifier = Provider.of<AuthNotifier>(context);
    final user = authNotifier.user;
    final origem = "app";
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pedidoPreview = Pedido(
      id: '',
      numeroPedido: 0,
      userId: user.uid,
      nomeUsuario: user.nome,
      telefone: user.telefone,
      itens: carrinho.itens,
      status: 'preview',
      data: DateTime.now(),
      impresso: false,
      endereco: controller.tipoEntrega == TipoEntrega.entrega
          ? user.enderecoFormatado
          : null,
      formaPagamento: [controller.formaPagamento],
      frete: controller.frete,
      tipoEntrega: controller.tipoEntrega.name,
      dataHoraEntrega: controller.dataHoraEntrega,
      cupomAplicado: controller.cupomAplicado,
    );

    final valorTotal = pedidoPreview.totalFinal;

    final dentroAlcance = controller.tipoEntrega == TipoEntrega.entrega
        ? PedidoValidador.validarAlcance(
      user.latitude,
      user.longitude,
    )
        : true;

    final pedidoOk = controller.tipoEntrega == TipoEntrega.entrega
        ? (PedidoValidador.validarValor(valorTotal) && dentroAlcance)
        : true;

    return AbertoConclusaoChecker(
        child: Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                controller.buildTipoEntrega(context),
                const SizedBox(height: 16),
                EnderecoCard(
                  endereco: user.enderecoFormatado,
                  goToPath: '/opcoes',
                ),
                const SizedBox(height: 8),
                if (controller.tipoEntrega == TipoEntrega.entrega &&
                    !dentroAlcance)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red, width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_off, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seu endereço pode estar fora da área de entrega '
                                '(${PedidoValidador.alcanceKm.toStringAsFixed(1)} km).',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  "Sugestões para você",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SugestoesTab(
                  sugestoes: controller.sugestoesProdutos,
                  acompanhamentosDisponiveis: controller.acompanhamentos,
                ),
                const SizedBox(height: 16),
                PagamentoSelector(controller: controller, carrinho: carrinho),
                const SizedBox(height: 16),
                const Text(
                  'Itens do Carrinho',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: carrinho.itens.length,
                  itemBuilder: (context, index) {
                    final item = carrinho.itens[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CarrinhoItemCard(
                        item: item,
                        index: index,
                        carrinho: carrinho,
                        controller: controller,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const CupomInput(),
                const SizedBox(height: 16),
                _buildTotais(pedidoPreview),
                const SizedBox(height: 16),
                if (controller.tipoEntrega == TipoEntrega.entrega &&
                    !PedidoValidador.validarValor(valorTotal))
                  PedidoMinimoAviso(
                    valorMinimo: PedidoValidador.valorMinimo,
                    tipoEntrega: controller.tipoEntrega,
                  ),
              ],
            ),
          ),
          // Botão flutuante acima do nav bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    pedidoOk ? Colors.greenAccent : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: controller.isLoading || !pedidoOk
                      ? null
                      : () => controller.finalizarPedido(
                    context,
                    carrinho,
                    authNotifier,
                  ),
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${valorTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Finalizar Pedido',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }
}

  Widget _buildTotais(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Itens', pedido.subtotal),
          const SizedBox(height: 8),
          _buildTotalRow('Frete', pedido.frete),
          if (pedido.cupomAplicado != null) ...[
            const Divider(color: Colors.black26),
            _buildTotalRow(
              'Desconto (${pedido.cupomAplicado!.codigo})',
              (pedido.subtotal + pedido.frete) - pedido.totalFinal,
              valueColor: Colors.red,
            ),
          ],
          const Divider(color: Colors.black26),
          _buildTotalRow(
            'Total',
            pedido.totalFinal,
            isBold: true,
            valueColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
      String label,
      double value, {
        bool isBold = false,
        Color valueColor = Colors.black,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
