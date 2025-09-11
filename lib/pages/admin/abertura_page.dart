import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:padariavinhos/notifiers/config_notifier.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';

class ConfigAberturaPage extends StatefulWidget {
  const ConfigAberturaPage({super.key});

  @override
  State<ConfigAberturaPage> createState() => _ConfigAberturaPageState();
}

class _ConfigAberturaPageState extends State<ConfigAberturaPage> {
  bool _aberto = false;
  TimeOfDay _horaAbertura = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFechamento = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = false;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final doc = await _firestore.collection('config').doc('abertura').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _aberto = data['aberto'] ?? false;
          final abertura = data['horaAbertura'] ?? '08:00';
          final fechamento = data['horaFechamento'] ?? '20:00';
          _horaAbertura = TimeOfDay(
              hour: int.parse(abertura.split(':')[0]),
              minute: int.parse(abertura.split(':')[1]));
          _horaFechamento = TimeOfDay(
              hour: int.parse(fechamento.split(':')[0]),
              minute: int.parse(fechamento.split(':')[1]));
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar configuração: $e');
      DialogHelper.showTemporaryToast(context, 'Erro ao carregar configuração');

    }
  }

  Future<void> _selecionarHoraAbertura() async {
    final picked = await showTimePicker(context: context, initialTime: _horaAbertura);
    if (picked != null) {
      setState(() => _horaAbertura = picked);
    }
  }

  Future<void> _selecionarHoraFechamento() async {
    final picked = await showTimePicker(context: context, initialTime: _horaFechamento);
    if (picked != null) {
      setState(() => _horaFechamento = picked);
    }
  }

  Future<void> _salvarConfiguracao() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('config').doc('abertura').set({
        'aberto': _aberto,
        'horaAbertura': '${_horaAbertura.hour.toString().padLeft(2, '0')}:${_horaAbertura.minute.toString().padLeft(2, '0')}',
        'horaFechamento': '${_horaFechamento.hour.toString().padLeft(2, '0')}:${_horaFechamento.minute.toString().padLeft(2, '0')}',
      });
      // Atualiza o notifier para refletir a mudança em tempo real no app
      final configNotifier = Provider.of<ConfigNotifier>(context, listen: false);
      configNotifier.updateAbertura(_aberto, _horaAbertura, _horaFechamento);

      DialogHelper.showTemporaryToast(context, 'Configuração salva com sucesso!');

    } catch (e) {
      debugPrint('Erro ao salvar configuração: $e');
      DialogHelper.showTemporaryToast(context,  'Erro ao salvar configuração');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Horário de Funcionamento'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Estabelecimento aberto'),
                value: _aberto,
                onChanged: (val) => setState(() => _aberto = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Hora de Abertura'),
                subtitle: Text('${_horaAbertura.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: _selecionarHoraAbertura,
              ),
              ListTile(
                title: const Text('Hora de Fechamento'),
                subtitle: Text('${_horaFechamento.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: _selecionarHoraFechamento,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.save),
                  label: const Text('Salvar Configuração', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _salvarConfiguracao,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
