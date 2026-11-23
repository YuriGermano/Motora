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

  final TextEditingController _buscaCtrl = TextEditingController();
  String _busca = '';
  String _tipoFiltro = 'Todos';
  String _mesFiltro = 'Todos';
  String _ordenacao = 'recente'; // recente, antigo, maior_valor, menor_valor

  static const List<String> _tiposFiltro = [
    'Todos',
    'Troca de óleo',
    'Revisão',
    'Pneus',
    'Freios',
    'Bateria',
    'Ar-condicionado',
    'Suspensão',
    'Alinhamento',
    'Balanceamento',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
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

  List<String> get _mesesDisponiveis {
    final set = <String>{};
    for (final s in _servicos) {
      if (s.data != null) {
        try {
          final d = DateTime.parse(s.data!).toLocal();
          set.add('${d.month.toString().padLeft(2, '0')}/${d.year}');
        } catch (_) {}
      }
    }
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return ['Todos', ...list];
  }

  List<Servico> get _servicosFiltrados {
    var list = _servicos.where((s) {
      if (_tipoFiltro != 'Todos' && s.tipo != _tipoFiltro) {
        return false;
      }
      if (_mesFiltro != 'Todos' && s.data != null) {
        try {
          final d = DateTime.parse(s.data!).toLocal();
          final mesAno = '${d.month.toString().padLeft(2, '0')}/${d.year}';
          if (mesAno != _mesFiltro) return false;
        } catch (_) {
          return false;
        }
      }
      if (_busca.trim().isNotEmpty) {
        final q = _busca.trim().toLowerCase();
        final matchTipo = s.tipo.toLowerCase().contains(q);
        final matchOficina = s.oficina?.toLowerCase().contains(q) ?? false;
        final matchDesc = s.descricao?.toLowerCase().contains(q) ?? false;
        if (!matchTipo && !matchOficina && !matchDesc) return false;
      }
      return true;
    }).toList();

    switch (_ordenacao) {
      case 'antigo':
        list.sort((a, b) => (a.data ?? '').compareTo(b.data ?? ''));
        break;
      case 'maior_valor':
        list.sort((a, b) => b.custo.compareTo(a.custo));
        break;
      case 'menor_valor':
        list.sort((a, b) => a.custo.compareTo(b.custo));
        break;
      case 'recente':
      default:
        list.sort((a, b) => (b.data ?? '').compareTo(a.data ?? ''));
        break;
    }
    return list;
  }

  void _limparFiltros() {
    setState(() {
      _buscaCtrl.clear();
      _busca = '';
      _tipoFiltro = 'Todos';
      _mesFiltro = 'Todos';
      _ordenacao = 'recente';
    });
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
    final filtrados = _servicosFiltrados;
    final temFiltroAtivo = _busca.isNotEmpty || _tipoFiltro != 'Todos' || _mesFiltro != 'Todos' || _ordenacao != 'recente';

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
                  : Column(
                      children: [
                        // Barra de busca
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: TextField(
                            controller: _buscaCtrl,
                            onChanged: (v) => setState(() => _busca = v),
                            decoration: InputDecoration(
                              hintText: 'Buscar por tipo, oficina ou descrição...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _busca.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setState(() {
                                        _buscaCtrl.clear();
                                        _busca = '';
                                      }),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),

                        // Chips de tipo de serviço
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _tiposFiltro.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final tipo = _tiposFiltro[i];
                              final isSelected = _tipoFiltro == tipo;
                              return ChoiceChip(
                                label: Text(tipo),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _tipoFiltro = selected ? tipo : 'Todos';
                                  });
                                },
                              );
                            },
                          ),
                        ),

                        // Filtros de Mês e Ordenação
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _mesFiltro,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'Mês',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: _mesesDisponiveis.map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m == 'Todos' ? 'Todos os meses' : m, style: const TextStyle(fontSize: 12)),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _mesFiltro = v ?? 'Todos'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _ordenacao,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'Ordenar por',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'recente', child: Text('Mais recente', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'antigo', child: Text('Mais antigo', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'maior_valor', child: Text('Maior valor', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'menor_valor', child: Text('Menor valor', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (v) => setState(() => _ordenacao = v ?? 'recente'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Resumo dos filtros e total gasto
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtrados.length} ${filtrados.length == 1 ? "serviço" : "serviços"}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              if (temFiltroAtivo)
                                GestureDetector(
                                  onTap: _limparFiltros,
                                  child: const Text(
                                    'Limpar filtros',
                                    style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (filtrados.isNotEmpty)
                                Text(
                                  'Total: R\$ ${filtrados.fold<double>(0, (sum, s) => sum + s.custo).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 8),

                        // Lista filtrada ou Estado Vazio
                        Expanded(
                          child: filtrados.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.search_off, size: 50, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      const Text('Nenhum serviço encontrado',
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _limparFiltros,
                                        child: const Text('Limpar filtros'),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _carregar,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                                    itemCount: filtrados.length,
                                    itemBuilder: (context, i) {
                                      final s = filtrados[i];
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
                        ),
                      ],
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
