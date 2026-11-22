import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Tela de serviços e manutenções do veículo
class ServicosScreen extends StatefulWidget {
  final int veiculoId;
  const ServicosScreen({super.key, required this.veiculoId});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  List<Servico> _servicos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await ApiService.getServicos(widget.veiculoId);
      setState(() { _servicos = lista; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Erro ao carregar serviços'; _loading = false; });
    }
  }

  Future<void> _excluir(Servico s) async {
    try {
      await ApiService.excluirServico(s.id!);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  static const Map<String, IconData> _tipoIcones = {
    'Troca de óleo': Icons.oil_barrel,
    'Revisão': Icons.build_circle,
    'Pneus': Icons.tire_repair,
    'Freios': Icons.warning_amber,
    'Bateria': Icons.battery_charging_full,
    'Ar-condicionado': Icons.ac_unit,
    'Suspensão': Icons.car_repair,
    'Outros': Icons.handyman,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _servicos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Nenhum serviço registrado',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _servicos.length,
                        itemBuilder: (context, i) {
                          final s = _servicos[i];
                          final icone = _tipoIcones[s.tipo] ?? Icons.build;
                          return Dismissible(
                            key: Key('servico-${s.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: AppColors.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async => await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir serviço?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                                ],
                              ),
                            ),
                            onDismissed: (_) => _excluir(s),
                            child: Card(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(icone, color: AppColors.primary),
                                ),
                                title: Text(s.tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${s.kmNoMomento.toStringAsFixed(0)} km  •  R\$ ${s.custo.toStringAsFixed(2)}'),
                                    if (s.oficina != null) Text(s.oficina!),
                                    if (s.descricao != null)
                                      Text(s.descricao!,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    if (s.proximaRevisaoKm != null)
                                      Row(children: [
                                        const Icon(Icons.update, size: 14, color: AppColors.accent),
                                        const SizedBox(width: 4),
                                        Text('Próx. revisão: ${s.proximaRevisaoKm!.toStringAsFixed(0)} km',
                                            style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                                      ]),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  s.data != null ? _formatDate(s.data!) : '',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _FormServico(veiculoId: widget.veiculoId),
          );
          if (resultado == true) _carregar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return iso; }
  }
}

class _FormServico extends StatefulWidget {
  final int veiculoId;
  const _FormServico({required this.veiculoId});
  @override
  State<_FormServico> createState() => _FormServicoState();
}

class _FormServicoState extends State<_FormServico> {
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  final _oficinalCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _proxKmCtrl = TextEditingController();
  final _proxDataCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String _tipo = 'Troca de óleo';
  bool _salvando = false;

  static const List<String> _tipos = [
    'Troca de óleo', 'Revisão', 'Pneus', 'Freios', 'Bateria',
    'Ar-condicionado', 'Suspensão', 'Alinhamento', 'Balanceamento', 'Outros',
  ];

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final servico = Servico(
      veiculoId: widget.veiculoId,
      kmNoMomento: double.parse(_kmCtrl.text),
      tipo: _tipo,
      descricao: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      custo: double.tryParse(_custoCtrl.text) ?? 0,
      oficina: _oficinalCtrl.text.isEmpty ? null : _oficinalCtrl.text,
      proximaRevisaoKm: double.tryParse(_proxKmCtrl.text),
      proximaRevisaoData: _proxDataCtrl.text.isEmpty ? null : _proxDataCtrl.text,
      observacao: _obsCtrl.text.isEmpty ? null : _obsCtrl.text,
    );

    try {
      await ApiService.registrarServico(servico);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _salvando = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: AppColors.error));
    } catch (_) {
      setState(() => _salvando = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão'), backgroundColor: AppColors.error));
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Registrar Serviço',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de serviço *'),
                items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _kmCtrl,
                    decoration: const InputDecoration(labelText: 'KM atual *', suffixText: 'km'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _custoCtrl,
                    decoration: const InputDecoration(labelText: 'Custo', prefixText: 'R\$ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                controller: _oficinalCtrl,
                decoration: const InputDecoration(labelText: 'Oficina (opcional)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _proxKmCtrl,
                    decoration: const InputDecoration(labelText: 'Próx. revisão (km)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _proxDataCtrl,
                    decoration: const InputDecoration(labelText: 'Próx. revisão (data)'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _salvando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.build),
                      label: const Text('Registrar serviço'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
