import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/notifiers/aberto_check.dart';
import '../helpers/acompanhamentos_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/helpers/date_utils.dart';

enum TipoEntrega { entrega, retirada, noLocal }


class ConclusaoPedidoPage extends StatefulWidget {
  @override
  State<ConclusaoPedidoPage> createState() => _ConclusaoPedidoPageState();
}

class _ConclusaoPedidoPageState extends State<ConclusaoPedidoPage> {
  bool _isLoading = false;
  String _formaPagamento = 'Pix';
  final List<String> _formasPagamento = ['Pix', 'Débito', 'Crédito', 'Voucher', 'Dinheiro'];
  List<Acompanhamento> _acompanhamentos = [];
  final double _freteEntrega = 4.0;
  TipoEntrega _tipoEntrega = TipoEntrega.entrega;

  /// Data e hora da entrega (opcional)
  DateTime? _dataEntrega;
  TimeOfDay? _horaEntrega;

  @override
  void initState() {
    super.initState();
    _carregarAcompanhamentos();
  }

  Future<void> _carregarAcompanhamentos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
      setState(() {
        _acompanhamentos = snapshot.docs
            .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar acompanhamentos: $e');
    }
  }

  void _finalizarPedido() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final user = authNotifier.user;

    if (!authNotifier.isAuthenticated || user == null) {
      DialogHelper.showTemporaryToast(context, 'Usuário não autenticado ou dados ainda não carregados.');
      setState(() => _isLoading = false);
      return;
    }

    if (carrinho.itens.isEmpty) {
      DialogHelper.showTemporaryToast(context, 'Seu carrinho está vazio!');
      setState(() => _isLoading = false);
      return;
    }

    double frete = _tipoEntrega == TipoEntrega.entrega ? _freteEntrega : 0.0;

  // Valida horário para entrega
    if (_tipoEntrega == TipoEntrega.entrega) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        _dataEntrega?.year ?? now.year,
        _dataEntrega?.month ?? now.month,
        _dataEntrega?.day ?? now.day,
        _horaEntrega?.hour ?? now.hour,
        _horaEntrega?.minute ?? now.minute,
    );

    if (selectedDateTime.isBefore(now.add(const Duration(hours: 1)))) {
       DialogHelper.showTemporaryToast(context, 'O horário de entrega deve ser pelo menos 1 hora após o pedido.');
       setState(() => _isLoading = false);
        return;
    }
  }

  try {
      final pedido = Pedido(
        id: '',
        numeroPedido: 0,
        userId: user.uid,
        nomeUsuario: user.nome,
        telefone: user.telefone,
        itens: carrinho.itens,
        status: 'pendente',
        data: DateTime.now(),
        impresso: false,
        endereco: _tipoEntrega == TipoEntrega.entrega ? user.enderecoFormatado : null,
        formaPagamento: [_formaPagamento],
        tipoEntrega: _tipoEntrega.name, // Salva o tipo de entrega
        dataEntrega: _dataEntrega,
        horaEntrega: _horaEntrega != null && _dataEntrega != null
            ? combineDateAndTime(_dataEntrega!, _horaEntrega!)
            : null,
        frete: frete,
      );

      await PedidoService().criarPedido(pedido);
      carrinho.limpar();

      if (context.mounted) {
        DialogHelper.showTemporaryToast(context, 'Pedido finalizado com sucesso!');
      }
    } catch (e) {
      debugPrint('Erro ao finalizar pedido: $e');
      DialogHelper.showTemporaryToast(context, 'Erro ao finalizar pedido');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editarObservacaoDialog(BuildContext context, String produtoId, String? observacaoAtual) {
    final controller = TextEditingController(text: observacaoAtual ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Observação'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex: Sem cebola, ponto da carne...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () {
              final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);
              final index = carrinho.itens.indexWhere((item) => item.produto.id == produtoId);
              if (index >= 0) {
                carrinho.atualizarObservacao(index, controller.text.trim());
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _editarAcompanhamentosDialog(BuildContext context, int index, ItemCarrinho item) {
    final carrinho = Provider.of<CarrinhoProvider>(context, listen: false);

    final acompanhamentosIds = item.produto.acompanhamentosIds;
    final acompanhamentosDisponiveisDoProduto = _acompanhamentos
        .where((a) => acompanhamentosIds.contains(a.id))
        .toList();

    List<String> selecionadosNomes = List.from(item.acompanhamentos?.map((a) => a.nome) ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Acompanhamentos - ${item.produto.nome}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (acompanhamentosDisponiveisDoProduto.isEmpty)
                    const Text('Nenhum acompanhamento disponível para este produto.')
                  else
                    Wrap(
                      spacing: 8,
                      children: acompanhamentosDisponiveisDoProduto.map((acomp) {
                        final isSelected = selecionadosNomes.contains(acomp.nome);
                        return FilterChip(
                          label: Text(acomp.nome),
                          selected: isSelected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                if (selecionadosNomes.length < 3) {
                                  selecionadosNomes.add(acomp.nome);
                                } else {
                                  DialogHelper.showTemporaryToast(context, 'Máximo de 3 acompanhamentos.');
                                }
                              } else {
                                selecionadosNomes.remove(acomp.nome);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final selecionadosObjetos = _acompanhamentos
                          .where((a) => selecionadosNomes.contains(a.nome))
                          .toList();
                      carrinho.atualizarAcompanhamentos(index, selecionadosObjetos);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar'),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Widget para selecionar tipo de entrega (Entrega / Retirada / No Local)
  Widget _buildTipoEntrega() {
  return _buildGlassCard(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text('Forma de Recebimento:', style: TextStyle(fontSize: 16)),
  const SizedBox(height: 8),
  Wrap(
  spacing: 8,
  children: TipoEntrega.values.map((tipo) {
  String label;
  switch (tipo) {
  case TipoEntrega.entrega:
  label = 'Entrega';
  break;
  case TipoEntrega.retirada:
  label = 'Retirada';
  break;
  case TipoEntrega.noLocal:
  label = 'No Local';
  break;
  }
  return ChoiceChip(
  label: Text(label),
  selected: _tipoEntrega == tipo,
  onSelected: (selected) {
  if (selected) {
  setState(() => _tipoEntrega = tipo);
  }
  },
  );
  }).toList(),
  ),
  if (_tipoEntrega == TipoEntrega.entrega) ...[
  const SizedBox(height: 8),
  Row(
  children: [
  ElevatedButton(
  onPressed: _selecionarData,
  child: Text(_dataEntrega == null
  ? 'Selecionar Data'
      : '${_dataEntrega!.day}/${_dataEntrega!.month}/${_dataEntrega!.year}'),
  ),
  const SizedBox(width: 8),
  ElevatedButton(
  onPressed: _selecionarHora,
  child: Text(_horaEntrega == null
  ? 'Selecionar Hora'
      : '${_horaEntrega!.format(context)}'),
  ),
  ],
  ),
  ],
  ],
  ),
  );
  }

  /// Seleciona data
  Future<void> _selecionarData() async {
  final now = DateTime.now();
  final pickedDate = await showDatePicker(
  context: context,
  initialDate: now,
  firstDate: now,
  lastDate: now.add(const Duration(days: 30)),
  );

  if (pickedDate != null) {
  setState(() => _dataEntrega = pickedDate);
  }
  }

  /// Seleciona hora
  Future<void> _selecionarHora() async {
  final now = DateTime.now();
  final initialTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
  final pickedTime = await showTimePicker(
  context: context,
  initialTime: initialTime,
  );

  if (pickedTime != null) {
  final pickedDateTime = DateTime(
  _dataEntrega?.year ?? now.year,
  _dataEntrega?.month ?? now.month,
  _dataEntrega?.day ?? now.day,
  pickedTime.hour,
  pickedTime.minute,
  );

  if (pickedDateTime.isBefore(now.add(const Duration(hours: 1)))) {
  DialogHelper.showTemporaryToast(context, 'O horário de entrega deve ser pelo menos 1 hora após o pedido.');
  return;
  }

  setState(() => _horaEntrega = pickedTime);
  }
  }


  @override
  Widget build(BuildContext context) {
    return AbertoChecker(
      child: Builder(
        builder: (context) {
          final carrinho = Provider.of<CarrinhoProvider>(context);
          final authNotifier = Provider.of<AuthNotifier>(context);

          if (authNotifier.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authNotifier.user == null) {
            return const Scaffold(
              body: Center(child: Text('Erro ao carregar dados do usuário.')),
            );
          }

          final user = authNotifier.user!;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Confirmar Pedido'),
              backgroundColor: Colors.red,
              elevation: 2,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: carrinho.itens.isEmpty
                    ? const Center(child: Text('Seu carrinho está vazio.'))
                    : Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/pedido'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Tipo de entrega
                    _buildTipoEntrega(),
                    const SizedBox(height: 12),

                    /// Endereço (para entrega)
                    if (_tipoEntrega == TipoEntrega.entrega)
                      _buildGlassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.enderecoFormatado,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    /// Forma de pagamento
                    _buildGlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Forma de Pagamento (Feito no local):',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          DropdownButton<String>(
                            value: _formaPagamento,
                            items: _formasPagamento
                                .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _formaPagamento = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Lista de itens
                    Expanded(
                      child: AnimatedList(
                        key: GlobalKey<AnimatedListState>(),
                        initialItemCount: carrinho.itens.length,
                        itemBuilder: (context, index, animation) {
                          final item = carrinho.itens[index];

                          return SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.vertical,
                            child: _buildGlassItemCard(item, index, carrinho),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Totais
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Itens:', style: TextStyle(fontSize: 16)),
                        Text('R\$ ${carrinho.total.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Frete:', style: TextStyle(fontSize: 16)),
                        Text('R\$ ${_tipoEntrega == TipoEntrega.entrega ? _freteEntrega.toStringAsFixed(2) : '0.00'}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          'R\$ ${(carrinho.total + (_tipoEntrega == TipoEntrega.entrega ? _freteEntrega : 0)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent.withOpacity(0.85),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _finalizarPedido,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Finalizar Pedido',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassItemCard(ItemCarrinho item, int index, CarrinhoProvider carrinho) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.lightGreenAccent.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        item.produto.imageUrl.isNotEmpty
                            ? item.produto.imageUrl.first
                            : 'assets/imagem_padrao.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.produto.nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Qtd: ${item.quantidade}',
                              style: const TextStyle(fontSize: 14)),
                          if ((item.observacao ?? '').isNotEmpty)
                            Text('Obs: ${item.observacao}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 14)),
                          if ((item.acompanhamentos ?? []).isNotEmpty)
                            Text(
                                'Acomp.: ${item.acompanhamentos!.map((a) => a.nome).join(', ')}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 14)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                carrinho.diminuirQuantidade(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                carrinho.aumentarQuantidade(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                carrinho.removerPorIndice(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _editarObservacaoDialog(context, item.produto.id, item.observacao);
                      },
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Editar Obs'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _editarAcompanhamentosDialog(context, index, item);
                      },
                      icon: const Icon(Icons.fastfood),
                      label: const Text('Editar Acomp.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}