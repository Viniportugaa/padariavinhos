import 'package:flutter/material.dart';
import '../models/acompanhamento.dart';

class AcompanhamentoProvider with ChangeNotifier {
  List<Acompanhamento> _selecionados = [];
  final int maxSelecionados;

  AcompanhamentoProvider({this.maxSelecionados = 3});

  List<Acompanhamento> get selecionados => _selecionados;

  bool adicionar(Acompanhamento ac) {
    if (_selecionados.length >= maxSelecionados) return false;
    _selecionados.add(ac);
    notifyListeners();
    return true;
  }

  void remover(Acompanhamento ac) {
    _selecionados.removeWhere((a) => a.id == ac.id);
    notifyListeners();
  }

  void limpar() {
    _selecionados.clear();
    notifyListeners();
  }

  bool estaSelecionado(Acompanhamento ac) =>
      selecionados.any((a) => a.id == ac.id);
}

