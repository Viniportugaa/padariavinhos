import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/auth_notifier.dart';

class AuthStatusPanel extends StatelessWidget {
  const AuthStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthNotifier>(context);

    // 🔍 Imprime os dados no console sempre que o widget for reconstruído
    debugPrint('[AuthStatusPanel] Autenticado: ${auth.isAuthenticated}');
    debugPrint('[AuthStatusPanel] Online: ${auth.isOnline}');
    debugPrint('[AuthStatusPanel] Papel: ${auth.role ?? 'Não definido'}');
    debugPrint('[AuthStatusPanel] Splash finalizada: ${auth.splashFinished}');
    if (auth.systemMessage != null) {
      debugPrint('[AuthStatusPanel] Mensagem: ${auth.systemMessage}');
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔐 Estado do AuthNotifier', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('✅ Autenticado: ${auth.isAuthenticated}'),
            Text('🌐 Online: ${auth.isOnline}'),
            Text('🧑 Papel: ${auth.role ?? 'Não definido'}'),
            Text('⏳ Splash finalizada: ${auth.splashFinished}'),
            if (auth.systemMessage!= null)
              Text('⚠️ Mensagem: ${auth.systemMessage}', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}