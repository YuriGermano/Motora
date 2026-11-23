import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
  double? _mediaConsumo;
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
      double? mediaConsumo;
      try {
        final abasts = await ApiService.getAbastecimentos(widget.veiculoId);
        mediaConsumo = CalculoConsumo.calcular(abasts).mediaGeral;
      } catch (_) {}

      setState(() {
        _dashboard = dashboard;
        _mediaConsumo = mediaConsumo;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Erro de conexão com a API'; _loading = false; });
    }
  }

  Future<void> _compartilharRelatorio() async {
    if (_dashboard == null) return;
    final d = _dashboard!;
    final v = d.veiculo;
    final totalGasto = d.totalGastoCombustivel + d.totalGastoServicos;

    String formatDate(String? iso) {
      if (iso == null) return '';
      try {
        final dt = DateTime.parse(iso).toLocal();
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        return iso;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('📋 *Relatório do Veículo - Motora*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🚗 *${v.apelido}* (${v.marca} ${v.modelo} ${v.ano})');
    buffer.writeln('🏷️ *Placa:* ${v.placa}');
    if (v.cor != null && v.cor!.trim().isNotEmpty) {
      buffer.writeln('🎨 *Cor:* ${v.cor}');
    }
    buffer.writeln('⛽ *Combustível:* ${v.combustivel}');
    buffer.writeln('⚡ *Quilometragem Atual:* ${v.kmAtual.toStringAsFixed(0)} km');
    buffer.writeln('');
    buffer.writeln('📊 *Resumo Financeiro & Manutenção:*');
    buffer.writeln('• Abastecimentos: ${d.totalAbastecimentos} (Total: R\$ ${d.totalGastoCombustivel.toStringAsFixed(2)})');
    buffer.writeln('• Serviços realizados: ${d.totalServicos} (Total: R\$ ${d.totalGastoServicos.toStringAsFixed(2)})');
    buffer.writeln('• Gasto total acumulado: R\$ ${totalGasto.toStringAsFixed(2)}');
    if (_mediaConsumo != null) {
      buffer.writeln('• Média de consumo: ${_mediaConsumo!.toStringAsFixed(2)} km/l');
    }
    buffer.writeln('• Alertas ativos: ${d.alertasAtivos}');

    if (d.ultimoAbastecimento != null) {
      final a = d.ultimoAbastecimento!;
      buffer.writeln('');
      buffer.writeln('⛽ *Último Abastecimento:*');
      buffer.writeln('• Volume: ${a.litros.toStringAsFixed(1)} L (R\$ ${a.total.toStringAsFixed(2)})');
      buffer.writeln('• Odômetro: ${a.kmNoMomento.toStringAsFixed(0)} km');
      if (a.posto != null) buffer.writeln('• Posto: ${a.posto}');
      if (a.data != null) buffer.writeln('• Data: ${formatDate(a.data)}');
    }

    if (d.ultimoServico != null) {
      final s = d.ultimoServico!;
      buffer.writeln('');
      buffer.writeln('🔧 *Último Serviço:*');
      buffer.writeln('• Tipo: ${s.tipo} (R\$ ${s.custo.toStringAsFixed(2)})');
      buffer.writeln('• Odômetro: ${s.kmNoMomento.toStringAsFixed(0)} km');
      if (s.oficina != null) buffer.writeln('• Oficina: ${s.oficina}');
      if (s.data != null) buffer.writeln('• Data: ${formatDate(s.data)}');
    }

    buffer.writeln('');
    buffer.writeln('📲 Gerado pelo app Motora');

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Relatório do Veículo - ${v.apelido}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dashboard?.veiculo.apelido ?? 'Carregando...'),
        actions: [
          if (_dashboard != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartilhar relatório',
              onPressed: _compartilharRelatorio,
            ),
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
          ],
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
                    _DashboardTab(
                      dashboard: _dashboard!,
                      mediaConsumo: _mediaConsumo,
                      onCompartilhar: _compartilharRelatorio,
                    ),
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
  final double? mediaConsumo;
  final VoidCallback onCompartilhar;

  const _DashboardTab({
    required this.dashboard,
    this.mediaConsumo,
    required this.onCompartilhar,
  });

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

          // Botão destacado de Compartilhar / Exportar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onCompartilhar,
              icon: const Icon(Icons.share, size: 20),
              label: const Text(
                'Compartilhar Resumo do Veículo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cards de estatísticas (Linha 1: Abastecimentos e Serviços)
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

          // Linha 2: Gasto total e Alertas ativos
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
          const SizedBox(height: 8),

          // Linha 3: Card de Consumo Médio (km/l)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MÉDIA DE CONSUMO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        Text(
                          mediaConsumo != null
                              ? '${mediaConsumo!.toStringAsFixed(2)} km/l'
                              : 'Sem dados suficientes',
                          style: TextStyle(
                            fontSize: mediaConsumo != null ? 20 : 15,
                            fontWeight: FontWeight.bold,
                            color: mediaConsumo != null ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          mediaConsumo != null
                              ? 'Baseado em abastecimentos com tanque cheio'
                              : 'Requer ao menos dois abastecimentos com tanque cheio',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
