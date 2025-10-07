import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/helpers/pedido_validador.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';
import 'package:padariavinhos/provider/carrinhos_provider.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'dart:ui';
import 'package:padariavinhos/models/cupom.dart';
import 'package:padariavinhos/models/produto.dart';

enum TipoEntrega { entrega, retirada, noLocal }

class ConclusaoPedidoController extends ChangeNotifier {
  final PedidoService _pedidoService = PedidoService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Produto> _sugestoesProdutos = [];
  List<Produto> get sugestoesProdutos => _sugestoesProdutos;

  double? _valorPago;
  double? get valorPago => _valorPago;

  double? _troco;
  double? get troco => _troco;

  void definirValorPago(double valor, double totalPedido) {
    _valorPago = valor;
    _troco = (valor > totalPedido) ? valor - totalPedido : 0;
    notifyListeners();
  }

  Cupom? _cupomAplicado;
  Cupom? get cupomAplicado => _cupomAplicado;

  String? _erroCupom;
  String? get erroCupom => _erroCupom;

  DateTime? _dataHoraEntrega;
  DateTime? get dataHoraEntrega => _dataHoraEntrega;

  TipoEntrega _tipoEntrega = TipoEntrega.entrega;
  TipoEntrega get tipoEntrega => _tipoEntrega;
  set tipoEntrega(TipoEntrega value) {
    _tipoEntrega = value;
    notifyListeners();
  }

  double freteEntrega = 4.0;
  double get frete => _tipoEntrega == TipoEntrega.entrega ? freteEntrega : 0.0;

  String _formaPagamento = 'Pix';
  String get formaPagamento => _formaPagamento;
  set formaPagamento(String value) {
    _formaPagamento = value;
    notifyListeners();
  }

  final List<String> formasPagamento = [
    'Pix',
    'Débito',
    'Crédito',
    'Voucher',
    'Dinheiro'
  ];

  List<Acompanhamento> _acompanhamentos = [];
  List<Acompanhamento> get acompanhamentos => _acompanhamentos;

  Future<void> carregarSugestoes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('produtos')
          .where('disponivel', isEqualTo: true)
          .where('category', whereIn: ['Doce', 'Refrigerante', 'Sucos']) // filtro por múltiplas categorias
          .limit(10)
          .get();

      _sugestoesProdutos = snapshot.docs
          .map((doc) => Produto.fromMap(doc.data(), doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar sugestões: $e');
    }
  }



  Future<void> aplicarCupom(String codigo, String userId) async {
    _erroCupom = null;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('cupons')
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _erroCupom = "Cupom não encontrado";
        notifyListeners();
        return;
      }

      final cupom = Cupom.fromMap(snap.docs.first.data(), snap.docs.first.id);

      if (!cupom.isValidoParaUsuario(userId)) {
        _erroCupom = "Cupom inválido, expirado ou já utilizado";
        notifyListeners();
        return;
      }

      _cupomAplicado = cupom;
      notifyListeners();
    } catch (e) {
      _erroCupom = "Erro ao validar cupom";
      debugPrint('Erro cupom: $e');
      notifyListeners();
    }
  }

  /// Remove o cupom aplicado
  void removerCupom() {
    _cupomAplicado = null;
    _erroCupom = null;
    notifyListeners();
  }


  /// Carrega acompanhamentos do Firestore
  Future<void> carregarAcompanhamentos() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('acompanhamentos').get();
      _acompanhamentos = snapshot.docs
          .map((doc) => Acompanhamento.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar acompanhamentos: $e');
    }
  }

  /// Card com efeito glass
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

  /// Modal de seleção de data e hora (sua lógica preservada)
  Future<DateTime?> _mostrarModalSelecionarDataHora(BuildContext context) async {
    final config = Provider.of<ConfigNotifier>(context, listen: false);
    final now = DateTime.now();

    // Se não for entrega, pergunta se quer definir data/hora
    if (_tipoEntrega != TipoEntrega.entrega) {
      final selecionar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Definir Horário?'),
          content: const Text('Deseja definir data e hora para este pedido?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Não')),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sim')),
          ],
        ),
      );
      if (selecionar != true) return null;
    }

    // Datas possíveis: próximos 14 dias
    final datas = List.generate(14, (i) => now.add(Duration(days: i)));
    DateTime? selectedDate;

    // Seleção de data
    selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        int currentPage = 0;
        final pageController = PageController(initialPage: 0);

        void scrollLeft() {
          if (currentPage > 0) {
            currentPage--;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        }

        void scrollRight() {
          if (currentPage < datas.length - 1) {
            currentPage++;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecione a Data',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                          onPressed: scrollLeft,
                          icon: const Icon(Icons.arrow_back_ios)),
                      Expanded(
                        child: SizedBox(
                          height: 100,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: datas.length,
                            onPageChanged: (index) => currentPage = index,
                            itemBuilder: (_, index) {
                              final date = datas[index];
                              return GestureDetector(
                                onTap: () => Navigator.pop(ctx, date),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${date.day}/${date.month}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text(
                                          [
                                            'Dom',
                                            'Seg',
                                            'Ter',
                                            'Qua',
                                            'Qui',
                                            'Sex',
                                            'Sáb'
                                          ][date.weekday % 7],
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: scrollRight,
                          icon: const Icon(Icons.arrow_forward_ios)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedDate == null) return null;

    // --- Seleção de hora ---
    final hoje = DateTime(now.year, now.month, now.day);
    final abertura = config.horaAbertura;
    final fechamento = config.horaFechamento;

    DateTime startTime;
    if (_tipoEntrega == TipoEntrega.entrega) {
      if (DateTime(selectedDate.year, selectedDate.month, selectedDate.day) ==
          hoje) {
        startTime = now.add(const Duration(minutes: 30));
        final aberturaHoje = DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, abertura.hour, abertura.minute);
        if (startTime.isBefore(aberturaHoje)) startTime = aberturaHoje;
      } else {
        startTime = DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, abertura.hour, abertura.minute);
      }
    } else {
      startTime = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, 0, 0);
    }

    final endTime = (_tipoEntrega == TipoEntrega.entrega)
        ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        fechamento.hour, fechamento.minute)
        .subtract(const Duration(minutes: 40))
        : DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 50);

    final horas = <TimeOfDay>[];
    for (int h = startTime.hour; h <= endTime.hour; h++) {
      for (int m = 0; m < 60; m += 10) {
        final dt = DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day, h, m);
        if (dt.isAfter(startTime) && dt.isBefore(endTime)) {
          horas.add(TimeOfDay(hour: h, minute: m));
        }
      }
    }

    if (horas.isEmpty) return null;

    final selectedTime = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        int currentPage = 0;
        final pageController = PageController(initialPage: 0);

        void scrollLeft() {
          if (currentPage > 0) {
            currentPage--;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        }

        void scrollRight() {
          if (currentPage < horas.length - 1) {
            currentPage++;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecione o Horário',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                          onPressed: scrollLeft,
                          icon: const Icon(Icons.arrow_back_ios)),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: horas.length,
                            onPageChanged: (index) => currentPage = index,
                            itemBuilder: (_, index) {
                              final hora = horas[index];
                              return GestureDetector(
                                onTap: () => Navigator.pop(ctx, hora),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: scrollRight,
                          icon: const Icon(Icons.arrow_forward_ios)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedTime == null) return null;

    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
        selectedTime.hour, selectedTime.minute);
  }

  /// Selecionar data e hora
  Future<void> selecionarDataHora(BuildContext context) async {
    final dataHora = await _mostrarModalSelecionarDataHora(context);
    if (dataHora != null) {
      _dataHoraEntrega = dataHora;
      notifyListeners();
      DialogHelper.showTemporaryToast(
        context,
        'Entrega: ${_dataHoraEntrega!.day}/${_dataHoraEntrega!.month} '
            '${_dataHoraEntrega!.hour.toString().padLeft(2, '0')}:${_dataHoraEntrega!.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  /// Widget profissional para selecionar Tipo de Entrega e Data/Hora
  Widget buildTipoEntrega(BuildContext context) {
    return Consumer<ConclusaoPedidoController>(
      builder: (context, controller, _) {
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forma de Recebimento:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: TipoEntrega.values.map((tipo) {
                  String label;
                  Color chipColor;
                  switch (tipo) {
                    case TipoEntrega.entrega:
                      label = 'Entrega';
                      chipColor = Colors.deepOrangeAccent;
                      break;
                    case TipoEntrega.retirada:
                      label = 'Retirada';
                      chipColor = Colors.blueAccent;
                      break;
                    case TipoEntrega.noLocal:
                      label = 'No Local';
                      chipColor = Colors.greenAccent;
                      break;
                  }
                  return ChoiceChip(
                    label: Text(label,
                        style: const TextStyle(color: Colors.black45)),
                    selected: controller.tipoEntrega == tipo,
                    selectedColor: chipColor,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    onSelected: (selected) {
                      if (selected) controller.tipoEntrega = tipo;
                    },
                    labelPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    elevation: controller.tipoEntrega == tipo ? 4 : 0,
                    shadowColor: Colors.black45,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: () => controller.selecionarDataHora(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent.withOpacity(0.95),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                label: Text(
                  controller.dataHoraEntrega == null
                      ? 'Selecionar Data e Hora'
                      : '${controller.dataHoraEntrega!.day.toString().padLeft(2, '0')}/'
                      '${controller.dataHoraEntrega!.month.toString().padLeft(2, '0')}/'
                      '${controller.dataHoraEntrega!.year} '
                      '${controller.dataHoraEntrega!.hour.toString().padLeft(2, '0')}:'
                      '${controller.dataHoraEntrega!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              if (controller.dataHoraEntrega != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Entrega agendada para: '
                        '${controller.dataHoraEntrega!.day.toString().padLeft(2, '0')}/'
                        '${controller.dataHoraEntrega!.month.toString().padLeft(2, '0')} '
                        'às ${controller.dataHoraEntrega!.hour.toString().padLeft(2, '0')}:'
                        '${controller.dataHoraEntrega!.minute.toString().padLeft(2, '0')}',
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Finaliza pedido
  Future<void> finalizarPedido(
      BuildContext context,
      CarrinhoProvider carrinho,
      AuthNotifier authNotifier,
      ) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    final user = authNotifier.user;
    if (!authNotifier.isAuthenticated || user == null) {
      DialogHelper.showTemporaryToast(
        context,
        'Usuário não autenticado ou dados ainda não carregados.',
      );
      _resetLoading();
      return;
    }

    if (carrinho.itens.isEmpty) {
      DialogHelper.showTemporaryToast(context, 'Seu carrinho está vazio!');
      _resetLoading();
      return;
    }

    if (_tipoEntrega == TipoEntrega.entrega) {
      if (_dataHoraEntrega == null) {
        DialogHelper.showTemporaryToast(
          context,
          'Selecione a data e hora de entrega.',
        );
        _resetLoading();
        return;
      }

      if (user.location.latitude == null || user.location.longitude == null) {
        DialogHelper.showTemporaryToast(
          context,
          'Endereço inválido. Atualize no perfil.',
        );
        _resetLoading();
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
        endereco: _tipoEntrega == TipoEntrega.entrega
            ? user.enderecoFormatado
            : null,
        formaPagamento: [_formaPagamento],
        tipoEntrega: _tipoEntrega.name,
        dataHoraEntrega: _tipoEntrega == TipoEntrega.entrega
            ? _dataHoraEntrega!
            : null,
        frete: frete,
        cupomAplicado: _cupomAplicado,
        valorPago: _formaPagamento == 'Dinheiro' ? _valorPago : null,
        troco: _formaPagamento == 'Dinheiro' ? _troco : null,

      );

      await _pedidoService.criarPedido(pedido);

      carrinho.limpar();
      if (context.mounted) {
        DialogHelper.showTemporaryToast(
          context,
          'Pedido finalizado com sucesso!',
        );
      }
    } on FirebaseException catch (e, st) {
      debugPrint('❌ FirebaseException ao finalizar pedido: ${e.code} - ${e.message}');
      debugPrint('📌 Stack trace: $st');

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro Firebase'),
            content: Text(
                'Código: ${e.code}\nMensagem: ${e.message}\nMais detalhes no console.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Erro genérico ao finalizar pedido: $e');
      debugPrint('📌 Stack trace: $st');

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erro ao finalizar pedido'),
            content: Text('Detalhes: $e\nMais detalhes no console.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }
    } finally {
      _resetLoading();
    }
  }

  void _resetLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
