import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/router.dart';

import '../services/transitions.dart';

class SuaContaPage extends StatefulWidget {

  @override
  State<SuaContaPage> createState() => _SuaContaPageState();
}

class _SuaContaPageState extends State<SuaContaPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Dados da sua conta")),
        body: Center(child: Text("Hello World")),


    );
  }
}