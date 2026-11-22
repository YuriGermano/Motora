import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Tela de cadastro de novo veículo
class CadastrarVeiculoScreen extends StatefulWidget {
  final Veiculo? veiculoExistente; // se passado, entra em modo de edição

  const CadastrarVeiculoScreen({super.key, this.veiculoExistente});

  @override
  State<CadastrarVeiculoScreen> createState() => _CadastrarVeiculoScreenState();
}

class _CadastrarVeiculoScreenState extends State<CadastrarVeiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apelidoCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();

  String _combustivel = 'Gasolina';
  bool _salvando = false;

  final List<String> _combustiveis = ['Gasolina', 'Etanol', 'Flex', 'Diesel', 'GNV', 'Elétrico'];

  @override
  void initState() {
    super.initState();
    if (widget.veiculoExistente != null) {
      final v = widget.veiculoExistente!;
      _apelidoCtrl.text = v.apelido;
      _marcaCtrl.text = v.marca;
      _modeloCtrl.text = v.modelo;
      _anoCtrl.text = v.ano.toString();
      _placaCtrl.text = v.placa;
      _corCtrl.text = v.cor ?? '';
      _kmCtrl.text = v.kmAtual.toString();
      _combustivel = v.combustivel;
    }
  }

  @override
  void dispose() {
    _apelidoCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anoCtrl.dispose();
    _placaCtrl.dispose();
    _corCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final veiculo = Veiculo(
      id: widget.veiculoExistente?.id,
      apelido: _apelidoCtrl.text.trim(),
      marca: _marcaCtrl.text.trim(),
      modelo: _modeloCtrl.text.trim(),
      ano: int.parse(_anoCtrl.text),
      placa: _placaCtrl.text.trim().toUpperCase(),
      cor: _corCtrl.text.trim().isEmpty ? null : _corCtrl.text.trim(),
      combustivel: _combustivel,
      kmAtual: double.tryParse(_kmCtrl.text) ?? 0,
    );

    try {
      if (widget.veiculoExistente == null) {
        await ApiService.criarVeiculo(veiculo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veículo cadastrado!'), backgroundColor: AppColors.success),
          );
        }
      } else {
        await ApiService.atualizarVeiculo(veiculo.id!, veiculo.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veículo atualizado!'), backgroundColor: AppColors.success),
          );
        }
      }
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
          SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.veiculoExistente != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Veículo' : 'Novo Veículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection('Informações básicas'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apelidoCtrl,
                decoration: const InputDecoration(labelText: 'Apelido *', hintText: 'Ex: Meu Civic'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _marcaCtrl,
                    decoration: const InputDecoration(labelText: 'Marca *', hintText: 'Honda'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modeloCtrl,
                    decoration: const InputDecoration(labelText: 'Modelo *', hintText: 'Civic'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _anoCtrl,
                    decoration: const InputDecoration(labelText: 'Ano *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obrigatório';
                      final ano = int.tryParse(v);
                      if (ano == null || ano < 1900 || ano > 2100) return 'Ano inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _placaCtrl,
                    decoration: const InputDecoration(labelText: 'Placa *', hintText: 'ABC-1234'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _corCtrl,
                    decoration: const InputDecoration(labelText: 'Cor', hintText: 'Prata'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _combustivel,
                    decoration: const InputDecoration(labelText: 'Combustível'),
                    items: _combustiveis
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _combustivel = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kmCtrl,
                decoration: const InputDecoration(labelText: 'Quilometragem atual (km)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              _salvando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Salvar alterações' : 'Cadastrar veículo'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
      );
}
