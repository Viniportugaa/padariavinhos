import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/models/pedido.dart';
import 'package:padariavinhos/models/item_carrinho.dart';
import 'package:padariavinhos/models/acompanhamento.dart';
import 'package:padariavinhos/services/pedido_service.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';
import 'package:padariavinhos/services/auth_notifier.dart';
import 'package:padariavinhos/services/carrinhos_provider.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'dart:ui';

enum TipoEntrega { entrega, retirada, noLocal }

class ConclusaoPedidoController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  final List<String> formasPagamento = ['Pix', 'Débito', 'Crédito', 'Voucher', 'Dinheiro'];

  List<Acompanhamento> _acompanhamentos = [];
  List<Acompanhamento> get acompanhamentos => _acompanhamentos;

  /// Carrega acompanhamentos do Firestore
  Future<void> carregarAcompanhamentos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('acompanhamentos').get();
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

  /// Modal de seleção de data e hora
  Future<DateTime?> _mostrarModalSelecionarDataHora(BuildContext context) async {
    final config = Provider.of<ConfigNotifier>(context, listen: false);

    final now = DateTime.now();
    final abertura = config.horaAbertura;
    final fechamento = config.horaFechamento;

    final datas = List.generate(14, (i) => now.add(Duration(days: i))); // próximos 14 dias
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    // --- Seleção de data ---
    selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final pageController = PageController(initialPage: 0);
        int currentPage = 0;

        void scrollLeft() {
          if (currentPage > 0) {
            currentPage--;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        }

        void scrollRight() {
          if (currentPage < datas.length - 1) {
            currentPage++;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  const Text('Selecione a Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(onPressed: scrollLeft, icon: const Icon(Icons.arrow_back_ios)),
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
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${date.day}/${date.month}',
                                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text(
                                        ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'][date.weekday % 7],
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(onPressed: scrollRight, icon: const Icon(Icons.arrow_forward_ios)),
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
    final startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute)
        .add(const Duration(minutes: 30));

    final endTime = (_tipoEntrega == TipoEntrega.entrega)
        ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, fechamento.hour, fechamento.minute)
        .subtract(const Duration(minutes: 20))
        : DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 50);

    final horas = <TimeOfDay>[];
    for (int h = startTime.hour; h <= endTime.hour; h++) {
      for (int m = 0; m < 60; m += 10) {
        final dt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, h, m);
        if (dt.isAfter(startTime) && dt.isBefore(endTime)) {
          horas.add(TimeOfDay(hour: h, minute: m));
        }
      }
    }

    selectedTime = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final pageController = PageController(initialPage: 0);
        int currentPage = 0;

        void scrollLeft() {
          if (currentPage > 0) {
            currentPage--;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        }

        void scrollRight() {
          if (currentPage < horas.length - 1) {
            currentPage++;
            pageController.animateToPage(currentPage,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  const Text('Selecione o Horário', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(onPressed: scrollLeft, icon: const Icon(Icons.arrow_back_ios)),
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
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${hora.hour.toString().padLeft(2,'0')}:${hora.minute.toString().padLeft(2,'0')}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(onPressed: scrollRight, icon: const Icon(Icons.arrow_forward_ios)),
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

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
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
            '${_dataHoraEntrega!.hour.toString().padLeft(2,'0')}:${_dataHoraEntrega!.minute.toString().padLeft(2,'0')}',
      );
    }
  }

  /// Widget para selecionar tipo de entrega + data/hora
  Widget buildTipoEntrega(BuildContext context) {
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
                  if (selected) tipoEntrega = tipo;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (_tipoEntrega == TipoEntrega.entrega ||
              _tipoEntrega == TipoEntrega.retirada ||
              _tipoEntrega == TipoEntrega.noLocal)
            ElevatedButton(
              onPressed: () => selecionarDataHora(context),
              child: Text(
                _dataHoraEntrega == null
                    ? 'Selecionar Data e Hora'
                    : '${_dataHoraEntrega!.day}/${_dataHoraEntrega!.month}/${_dataHoraEntrega!.year} '
                    '${_dataHoraEntrega!.hour.toString().padLeft(2,'0')}:${_dataHoraEntrega!.minute.toString().padLeft(2,'0')}',
              ),
            ),
        ],
      ),
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
      DialogHelper.showTemporaryToast(context, 'Usuário não autenticado ou dados ainda não carregados.');
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (carrinho.itens.isEmpty) {
      DialogHelper.showTemporaryToast(context, 'Seu carrinho está vazio!');
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_tipoEntrega == TipoEntrega.entrega && _dataHoraEntrega == null) {
      DialogHelper.showTemporaryToast(context, 'Selecione a data e hora de entrega.');
      _isLoading = false;
      notifyListeners();
      return;
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
        tipoEntrega: _tipoEntrega.name,
        dataHoraEntrega: _tipoEntrega == TipoEntrega.entrega ? _dataHoraEntrega : _dataHoraEntrega,
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
      _isLoading = false;
      notifyListeners();
    }
  }
}
