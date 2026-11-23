import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Tela de abastecimentos do veículo
class AbastecimentoScreen extends StatefulWidget {
  final int veiculoId;
  const AbastecimentoScreen({super.key, required this.veiculoId});

  @override
  State<AbastecimentoScreen> createState() => _AbastecimentoScreenState();
}

class _AbastecimentoScreenState extends State<AbastecimentoScreen> {
  List<Abastecimento> _abastecimentos = [];
  CalculoConsumo _calculo = CalculoConsumo(mediasPorId: {}, mediaGeral: null, totalCiclos: 0);
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
      final lista = await ApiService.getAbastecimentos(widget.veiculoId);
      final calc = CalculoConsumo.calcular(lista);
      setState(() {
        _abastecimentos = lista;
        _calculo = calc;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Erro ao carregar abastecimentos'; _loading = false; });
    }
  }

  Future<void> _excluir(Abastecimento a) async {
    try {
      await ApiService.excluirAbastecimento(a.id!);
      _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _abastecimentos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_gas_station, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Nenhum abastecimento registrado',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 8, left: 12, right: 12),
                        itemCount: _abastecimentos.length + (_calculo.mediaGeral != null ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_calculo.mediaGeral != null && i == 0) {
                            return _buildHeaderConsumo();
                          }
                          final a = _abastecimentos[_calculo.mediaGeral != null ? i - 1 : i];
                          final mediaItem = _calculo.mediasPorId[a.id];

                          return Dismissible(
                            key: Key('abast-${a.id}'),
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
                                title: const Text('Excluir abastecimento?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                                ],
                              ),
                            ),
                            onDismissed: (_) => _excluir(a),
                            child: Card(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.local_gas_station, color: AppColors.accent),
                                ),
                                title: Text('${a.litros.toStringAsFixed(1)} L  •  R\$ ${a.total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${a.kmNoMomento.toStringAsFixed(0)} km  •  R\$ ${a.precoPorLitro.toStringAsFixed(3)}/L'
                                  '${a.posto != null ? "  •  ${a.posto}" : ""}'
                                  '${a.combustivel != null ? "\n${a.combustivel}" : ""}'
                                  '${a.tanqueCheio == 1 ? (mediaItem != null ? "  •  Tanque cheio" : "  •  Tanque cheio (início)") : "  •  Tanque parcial"}',
                                ),
                                isThreeLine: a.combustivel != null,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      a.data != null ? _formatDate(a.data!) : '',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                    if (mediaItem != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.green.shade600, width: 0.8),
                                        ),
                                        child: Text(
                                          '${mediaItem.toStringAsFixed(2)} km/l',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
            builder: (_) => _FormAbastecimento(veiculoId: widget.veiculoId),
          );
          if (resultado == true) _carregar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeaderConsumo() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.accent.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.speed, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÉDIA DE CONSUMO',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_calculo.mediaGeral!.toStringAsFixed(2)} km/l',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    'Calculado sobre ${_calculo.totalCiclos} ${_calculo.totalCiclos == 1 ? "ciclo" : "ciclos"} com tanque cheio (Δkm / Litros)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

/// Formulário em bottom sheet para novo abastecimento
class _FormAbastecimento extends StatefulWidget {
  final int veiculoId;
  const _FormAbastecimento({required this.veiculoId});

  @override
  State<_FormAbastecimento> createState() => _FormAbastecimentoState();
}

class _FormAbastecimentoState extends State<_FormAbastecimento> {
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _litrosCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  String _combustivel = 'Gasolina';
  bool _tanqueCheio = true;
  bool _salvando = false;

  double get _total {
    final litros = double.tryParse(_litrosCtrl.text) ?? 0;
    final preco = double.tryParse(_precoCtrl.text) ?? 0;
    return litros * preco;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final abastecimento = Abastecimento(
      veiculoId: widget.veiculoId,
      kmNoMomento: double.parse(_kmCtrl.text),
      litros: double.parse(_litrosCtrl.text),
      precoPorLitro: double.parse(_precoCtrl.text),
      total: _total,
      posto: _postoCtrl.text.isEmpty ? null : _postoCtrl.text,
      combustivel: _combustivel,
      tanqueCheio: _tanqueCheio ? 1 : 0,
      observacao: _obsCtrl.text.isEmpty ? null : _obsCtrl.text,
    );

    try {
      await ApiService.registrarAbastecimento(abastecimento);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão'), backgroundColor: AppColors.error),
        );
      }
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
              const Text('Registrar Abastecimento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmCtrl,
                decoration: const InputDecoration(labelText: 'KM atual *', suffixText: 'km'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litrosCtrl,
                      decoration: const InputDecoration(labelText: 'Litros *', suffixText: 'L'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _precoCtrl,
                      decoration: const InputDecoration(labelText: 'R\$/Litro *', prefixText: 'R\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Total: R\$ ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _combustivel,
                decoration: const InputDecoration(labelText: 'Combustível'),
                items: ['Gasolina', 'Etanol', 'Flex', 'Diesel', 'GNV']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _combustivel = v!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _postoCtrl,
                decoration: const InputDecoration(labelText: 'Posto (opcional)'),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _tanqueCheio,
                onChanged: (v) => setState(() => _tanqueCheio = v ?? true),
                title: const Text('Tanque cheio'),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(labelText: 'Observação (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _salvando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.local_gas_station),
                      label: const Text('Registrar abastecimento'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
