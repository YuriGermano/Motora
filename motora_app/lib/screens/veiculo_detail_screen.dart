import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'abastecimento_screen.dart';
import 'servicos_screen.dart';
import 'alertas_screen.dart';
import 'cadastrar_veiculo_screen.dart';

/// Tela de detalhe do veículo — tabs: Dashboard | Abastecimentos | Serviços | Alertas
class VeiculoDetailScreen extends StatefulWidget {
  final int veiculoId;

  const VeiculoDetailScreen({super.key, required this.veiculoId});

  @override
  State<VeiculoDetailScreen> createState() => _VeiculoDetailScreenState();
}

class _VeiculoDetailScreenState extends State<VeiculoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DashboardVeiculo? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _carregarDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dashboard = await ApiService.getDashboard(widget.veiculoId);
      setState(() { _dashboard = dashboard; _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Erro de conexão com a API'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dashboard?.veiculo.apelido ?? 'Carregando...'),
        actions: [
          if (_dashboard != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar veículo',
              onPressed: () async {
                final resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CadastrarVeiculoScreen(veiculoExistente: _dashboard!.veiculo),
                  ),
                );
                if (resultado == true) _carregarDashboard();
              },
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarDashboard),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumo'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Abast.'),
            Tab(icon: Icon(Icons.build), text: 'Serviços'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Alertas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _DashboardTab(dashboard: _dashboard!),
                    AbastecimentoScreen(veiculoId: widget.veiculoId),
                    ServicosScreen(veiculoId: widget.veiculoId),
                    AlertasScreen(veiculoId: widget.veiculoId),
                  ],
                ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 60),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _carregarDashboard, child: const Text('Tentar novamente')),
          ],
        ),
      );
}

/// Aba de dashboard/resumo do veículo
class _DashboardTab extends StatelessWidget {
  final DashboardVeiculo dashboard;
  const _DashboardTab({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final v = dashboard.veiculo;
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card principal do veículo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car, color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.apelido,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('${v.marca} ${v.modelo} ${v.ano}',
                                style: const TextStyle(color: AppColors.textSecondary)),
                            Text('Placa: ${v.placa}', style: const TextStyle(color: AppColors.textSecondary)),
                            Text('${v.combustivel} • ${v.cor ?? ''}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.speed, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${v.kmAtual.toStringAsFixed(0)} km',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Text('rodados', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Cards de estatísticas
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_gas_station,
                  color: AppColors.accent,
                  titulo: 'Abastecimentos',
                  valor: dashboard.totalAbastecimentos.toString(),
                  subtitulo: 'R\$ ${dashboard.totalGastoCombustivel.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.build,
                  color: AppColors.primary,
                  titulo: 'Serviços',
                  valor: dashboard.totalServicos.toString(),
                  subtitulo: 'R\$ ${dashboard.totalGastoServicos.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money,
                  color: AppColors.success,
                  titulo: 'Gasto total',
                  valor: 'R\$ ${(dashboard.totalGastoCombustivel + dashboard.totalGastoServicos).toStringAsFixed(2)}',
                  subtitulo: 'combustível + serviços',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.notifications_active,
                  color: dashboard.alertasAtivos > 0 ? AppColors.error : AppColors.success,
                  titulo: 'Alertas ativos',
                  valor: dashboard.alertasAtivos.toString(),
                  subtitulo: dashboard.alertasAtivos > 0 ? 'Atenção necessária' : 'Tudo em dia',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Último abastecimento
          if (dashboard.ultimoAbastecimento != null) ...[
            const Text('Último abastecimento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 6),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_gas_station, color: AppColors.accent),
                title: Text('${dashboard.ultimoAbastecimento!.litros.toStringAsFixed(1)} L '
                    '• R\$ ${dashboard.ultimoAbastecimento!.total.toStringAsFixed(2)}'),
                subtitle: Text('${dashboard.ultimoAbastecimento!.kmNoMomento.toStringAsFixed(0)} km'
                    '${dashboard.ultimoAbastecimento!.posto != null ? " • ${dashboard.ultimoAbastecimento!.posto}" : ""}'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Último serviço
          if (dashboard.ultimoServico != null) ...[
            const Text('Último serviço',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 6),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build, color: AppColors.primary),
                title: Text(dashboard.ultimoServico!.tipo),
                subtitle: Text('${dashboard.ultimoServico!.kmNoMomento.toStringAsFixed(0)} km'
                    ' • R\$ ${dashboard.ultimoServico!.custo.toStringAsFixed(2)}'
                    '${dashboard.ultimoServico!.oficina != null ? " • ${dashboard.ultimoServico!.oficina}" : ""}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo;
  final String valor;
  final String subtitulo;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(titulo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(subtitulo,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
