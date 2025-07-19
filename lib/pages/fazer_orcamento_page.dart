import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/transitions.dart';

class FazerOrcamentoPage extends StatefulWidget {

  @override
  State<FazerOrcamentoPage> createState() => _FazerOrcamentoPageState();
}

  class _FazerOrcamentoPageState extends State<FazerOrcamentoPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Faça seu Orçamento")),
      body: Center(child: Text("Hello World")),
    );
  }
}