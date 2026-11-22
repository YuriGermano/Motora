import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Tela de alertas de manutenção do veículo
class AlertasScreen extends StatefulWidget {
  final int veiculoId;
  const AlertasScreen({super.key, required this.veiculoId});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Alerta> _alertas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final lista = await ApiService.getAlertas(widget.veiculoId);
      setState(() { _alertas = lista; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _excluir(Alerta a) async {
    try {
      await ApiService.excluirAlerta(a.id!);
      _carregar();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nenhum alerta configurado',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _alertas.length,
                  itemBuilder: (context, i) {
                    final a = _alertas[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          a.ativo == 1 ? Icons.notifications_active : Icons.notifications_off,
                          color: a.ativo == 1 ? AppColors.error : Colors.grey,
                        ),
                        title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (a.descricao != null) Text(a.descricao!),
                            if (a.kmLimite != null)
                              Text('KM limite: ${a.kmLimite!.toStringAsFixed(0)} km',
                                  style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                            if (a.dataLimite != null)
                              Text('Data: ${a.dataLimite}',
                                  style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _excluir(a),
                        ),
                        isThreeLine: a.descricao != null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _FormAlerta(veiculoId: widget.veiculoId),
          );
          if (resultado == true) _carregar();
        },
        child: const Icon(Icons.add_alert),
      ),
    );
  }
}

class _FormAlerta extends StatefulWidget {
  final int veiculoId;
  const _FormAlerta({required this.veiculoId});
  @override
  State<_FormAlerta> createState() => _FormAlertaState();
}

class _FormAlertaState extends State<_FormAlerta> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  bool _salvando = false;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final alerta = Alerta(
      veiculoId: widget.veiculoId,
      titulo: _tituloCtrl.text,
      descricao: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      kmLimite: double.tryParse(_kmCtrl.text),
      dataLimite: _dataCtrl.text.isEmpty ? null : _dataCtrl.text,
    );

    try {
      await ApiService.criarAlerta(alerta);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _salvando = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar alerta'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Novo Alerta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título *', hintText: 'Ex: Troca de óleo'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _kmCtrl,
                  decoration: const InputDecoration(labelText: 'KM limite', suffixText: 'km'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _dataCtrl,
                  decoration: const InputDecoration(labelText: 'Data limite', hintText: 'DD/MM/AAAA'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _salvando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.add_alert),
                    label: const Text('Criar alerta'),
                  ),
          ],
        ),
      ),
    );
  }
}
