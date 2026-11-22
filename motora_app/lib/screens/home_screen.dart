import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'veiculo_detail_screen.dart';
import 'cadastrar_veiculo_screen.dart';

/// Tela principal: lista todos os veículos cadastrados
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Veiculo> _veiculos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  Future<void> _carregarVeiculos() async {
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await ApiService.getVeiculos();
      setState(() { _veiculos = lista; _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'Não foi possível conectar à API. Verifique se o servidor está rodando.';
        _loading = false;
      });
    }
  }

  Future<void> _excluirVeiculo(Veiculo veiculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir veículo'),
        content: Text('Deseja excluir "${veiculo.apelido}"? Todos os registros serão removidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ApiService.excluirVeiculo(veiculo.id!);
        _carregarVeiculos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veículo excluído com sucesso'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_car_filled, color: Colors.white),
            SizedBox(width: 8),
            Text('Motora'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarVeiculos,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CadastrarVeiculoScreen()),
          );
          if (resultado == true) _carregarVeiculos();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Veículo'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _carregarVeiculos,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_veiculos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.garage_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Nenhum veículo cadastrado', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Toque no botão + para adicionar seu primeiro veículo',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarVeiculos,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _veiculos.length,
        itemBuilder: (context, index) => _VeiculoCard(
          veiculo: _veiculos[index],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VeiculoDetailScreen(veiculoId: _veiculos[index].id!)),
            );
            _carregarVeiculos();
          },
          onDelete: () => _excluirVeiculo(_veiculos[index]),
        ),
      ),
    );
  }
}

class _VeiculoCard extends StatelessWidget {
  final Veiculo veiculo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VeiculoCard({required this.veiculo, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(veiculo.apelido,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${veiculo.marca} ${veiculo.modelo} ${veiculo.ano}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Text('Placa: ${veiculo.placa}  •  ${veiculo.kmAtual.toStringAsFixed(0)} km',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: onDelete,
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
