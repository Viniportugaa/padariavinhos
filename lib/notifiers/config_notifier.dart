import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigNotifier extends ChangeNotifier {
  bool aberto = false;
  TimeOfDay horaAbertura = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay horaFechamento = const TimeOfDay(hour: 20, minute: 0);

  late final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  ConfigNotifier() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Inicia o listener em tempo real para a configuração
  void startListening() {
    _subscription = _firestore.collection('config').doc('abertura').snapshots().listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      final abertoFirebase = data['aberto'] ?? false;
      final aberturaStr = data['horaAbertura'] ?? '08:00';
      final fechamentoStr = data['horaFechamento'] ?? '20:00';

      final abertura = TimeOfDay(
        hour: int.parse(aberturaStr.split(':')[0]),
        minute: int.parse(aberturaStr.split(':')[1]),
      );
      final fechamento = TimeOfDay(
        hour: int.parse(fechamentoStr.split(':')[0]),
        minute: int.parse(fechamentoStr.split(':')[1]),
      );

      aberto = abertoFirebase;
      horaAbertura = abertura;
      horaFechamento = fechamento;

      notifyListeners();
    });
  }

  /// Atualiza manualmente (ex: ao salvar na tela de configuração)
  void updateAbertura(bool isOpen, TimeOfDay abertura, TimeOfDay fechamento) {
    aberto = isOpen;
    horaAbertura = abertura;
    horaFechamento = fechamento;
    notifyListeners();
  }

  /// Retorna true se o estabelecimento estiver aberto no momento atual
  bool get abertoAgora {
    if (!aberto) return false;

    final now = TimeOfDay.now();

    final startMinutes = horaAbertura.hour * 60 + horaAbertura.minute;
    final endMinutes = horaFechamento.hour * 60 + horaFechamento.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
