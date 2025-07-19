import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OpcoesPage extends StatefulWidget {
  @override
  _OpcoesPageState createState() => _OpcoesPageState();
}

class _OpcoesPageState extends State<OpcoesPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final addressNumberController = TextEditingController();
  final phoneController = TextEditingController();
  String emailAutenticado = '';

  late String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? '';
    emailAutenticado = user?.email ?? '';
    loadUserData();
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      nameController.text = data['nome'] ?? '';
      addressController.text = data['endereco'] ?? '';
      addressNumberController.text = data['numero_endereco'] ?? '';
      phoneController.text = data['telefone'] ?? '';
    }
  }

  Future<void> updateUserData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'nome': nameController.text.trim(),
        'endereco': addressController.text.trim(),
        'numero_endereco': addressNumberController.text.trim(),
        'telefone': phoneController.text.trim(),
      });
      print('Dados atualizados com sucesso!');
    } catch (e) {
      print('Erro ao atualizar dados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar dados')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Editar Dados")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Email autenticado: $emailAutenticado',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            TextFormField(controller: nameController, decoration: InputDecoration(labelText: 'Nome')),
            TextFormField(controller: addressController, decoration: InputDecoration(labelText: 'Endereço')),
            TextFormField(controller: addressNumberController, decoration: InputDecoration(labelText: 'Número')),
            TextFormField(controller: phoneController, decoration: InputDecoration(labelText: 'Telefone'), keyboardType: TextInputType.phone),
            SizedBox(height: 20),
            ElevatedButton(onPressed: updateUserData, child: Text("Salvar Alterações")),
          ],
        ),// ... os outros campos (nome, endereço, etc.),
      ),
    );
  }
}