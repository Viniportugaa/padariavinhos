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

  Future<void> deleteAccountWithPassword(String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Navigator.pop(context); // fecha loading
        throw Exception("Nenhum usuário autenticado.");
      }

      final uid = user.uid;

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      final pedidos = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('usuarioId', isEqualTo: uid)
          .get();
      for (var doc in pedidos.docs) {
        await doc.reference.delete();
      }

      final carrinho = await FirebaseFirestore.instance
          .collection('carrinho')
          .where('usuarioId', isEqualTo: uid)
          .get();
      for (var doc in carrinho.docs) {
        await doc.reference.delete();
      }

      await user.delete();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("A conta e todos os dados foram excluídos com sucesso!")),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      Navigator.pop(context); // fecha loading
      print("Erro ao excluir conta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: ${e.toString()}")),
      );
    }
  }

  void confirmarExclusaoConta() {
    final senhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Excluir conta"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Digite sua senha para confirmar a exclusão da conta."),
            SizedBox(height: 10),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              final senha = senhaController.text.trim();
              if (senha.isNotEmpty) {
                Navigator.pop(context);
                deleteAccountWithPassword(senha);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Digite a senha para continuar")),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text("Excluir"),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Editar Dados",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.black, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Email autenticado:',
                  style: theme.textTheme.titleMedium!.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  emailAutenticado,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 24),

                _buildTextField(nameController, "Nome", Icons.person),
                SizedBox(height: 16),
                _buildTextField(addressController, "Endereço", Icons.home),
                SizedBox(height: 16),
                _buildTextField(addressNumberController, "Número", Icons.format_list_numbered),
                SizedBox(height: 16),
                _buildTextField(phoneController, "Telefone", Icons.phone, keyboardType: TextInputType.phone),

                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: updateUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "Salvar Alterações",
                    style: TextStyle(fontSize: 16, color: Colors.white,),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: confirmarExclusaoConta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "Excluir Conta",
                    style: TextStyle(fontSize: 16, color: Colors.white,),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}