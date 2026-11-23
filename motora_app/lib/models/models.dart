// Modelos Dart — espelham os schemas da API

class Veiculo {
  final int? id;
  final String apelido;
  final String marca;
  final String modelo;
  final int ano;
  final String placa;
  final String? cor;
  final String combustivel;
  final double kmAtual;
  final String? createdAt;

  Veiculo({
    this.id,
    required this.apelido,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.placa,
    this.cor,
    this.combustivel = 'Gasolina',
    this.kmAtual = 0,
    this.createdAt,
  });

  factory Veiculo.fromJson(Map<String, dynamic> json) => Veiculo(
        id: json['id'],
        apelido: json['apelido'],
        marca: json['marca'],
        modelo: json['modelo'],
        ano: json['ano'],
        placa: json['placa'],
        cor: json['cor'],
        combustivel: json['combustivel'] ?? 'Gasolina',
        kmAtual: (json['km_atual'] ?? 0).toDouble(),
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        'apelido': apelido,
        'marca': marca,
        'modelo': modelo,
        'ano': ano,
        'placa': placa,
        if (cor != null) 'cor': cor,
        'combustivel': combustivel,
        'km_atual': kmAtual,
      };
}

class Abastecimento {
  final int? id;
  final int veiculoId;
  final double kmNoMomento;
  final double litros;
  final double precoPorLitro;
  final double total;
  final String? posto;
  final String? combustivel;
  final int tanqueCheio;
  final String? observacao;
  final String? data;

  Abastecimento({
    this.id,
    required this.veiculoId,
    required this.kmNoMomento,
    required this.litros,
    required this.precoPorLitro,
    required this.total,
    this.posto,
    this.combustivel,
    this.tanqueCheio = 1,
    this.observacao,
    this.data,
  });

  factory Abastecimento.fromJson(Map<String, dynamic> json) => Abastecimento(
        id: json['id'],
        veiculoId: json['veiculo_id'],
        kmNoMomento: (json['km_no_momento'] ?? 0).toDouble(),
        litros: (json['litros'] ?? 0).toDouble(),
        precoPorLitro: (json['preco_por_litro'] ?? 0).toDouble(),
        total: (json['total'] ?? 0).toDouble(),
        posto: json['posto'],
        combustivel: json['combustivel'],
        tanqueCheio: json['tanque_cheio'] ?? 1,
        observacao: json['observacao'],
        data: json['data'],
      );

  Map<String, dynamic> toJson() => {
        'veiculo_id': veiculoId,
        'km_no_momento': kmNoMomento,
        'litros': litros,
        'preco_por_litro': precoPorLitro,
        'total': total,
        if (posto != null) 'posto': posto,
        if (combustivel != null) 'combustivel': combustivel,
        'tanque_cheio': tanqueCheio,
        if (observacao != null) 'observacao': observacao,
      };
}

class Servico {
  final int? id;
  final int veiculoId;
  final double kmNoMomento;
  final String tipo;
  final String? descricao;
  final double custo;
  final String? oficina;
  final double? proximaRevisaoKm;
  final String? proximaRevisaoData;
  final String? observacao;
  final String? data;

  Servico({
    this.id,
    required this.veiculoId,
    required this.kmNoMomento,
    required this.tipo,
    this.descricao,
    this.custo = 0,
    this.oficina,
    this.proximaRevisaoKm,
    this.proximaRevisaoData,
    this.observacao,
    this.data,
  });

  factory Servico.fromJson(Map<String, dynamic> json) => Servico(
        id: json['id'],
        veiculoId: json['veiculo_id'],
        kmNoMomento: (json['km_no_momento'] ?? 0).toDouble(),
        tipo: json['tipo'],
        descricao: json['descricao'],
        custo: (json['custo'] ?? 0).toDouble(),
        oficina: json['oficina'],
        proximaRevisaoKm: json['proxima_revisao_km']?.toDouble(),
        proximaRevisaoData: json['proxima_revisao_data'],
        observacao: json['observacao'],
        data: json['data'],
      );

  Map<String, dynamic> toJson() => {
        'veiculo_id': veiculoId,
        'km_no_momento': kmNoMomento,
        'tipo': tipo,
        if (descricao != null) 'descricao': descricao,
        'custo': custo,
        if (oficina != null) 'oficina': oficina,
        if (proximaRevisaoKm != null) 'proxima_revisao_km': proximaRevisaoKm,
        if (proximaRevisaoData != null) 'proxima_revisao_data': proximaRevisaoData,
        if (observacao != null) 'observacao': observacao,
      };
}

class Alerta {
  final int? id;
  final int veiculoId;
  final String titulo;
  final String? descricao;
  final double? kmLimite;
  final String? dataLimite;
  final int ativo;

  Alerta({
    this.id,
    required this.veiculoId,
    required this.titulo,
    this.descricao,
    this.kmLimite,
    this.dataLimite,
    this.ativo = 1,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: json['id'],
        veiculoId: json['veiculo_id'],
        titulo: json['titulo'],
        descricao: json['descricao'],
        kmLimite: json['km_limite']?.toDouble(),
        dataLimite: json['data_limite'],
        ativo: json['ativo'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'veiculo_id': veiculoId,
        'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
        if (kmLimite != null) 'km_limite': kmLimite,
        if (dataLimite != null) 'data_limite': dataLimite,
        'ativo': ativo,
      };
}

class DashboardVeiculo {
  final Veiculo veiculo;
  final int totalAbastecimentos;
  final double totalGastoCombustivel;
  final int totalServicos;
  final double totalGastoServicos;
  final Abastecimento? ultimoAbastecimento;
  final Servico? ultimoServico;
  final int alertasAtivos;

  DashboardVeiculo({
    required this.veiculo,
    required this.totalAbastecimentos,
    required this.totalGastoCombustivel,
    required this.totalServicos,
    required this.totalGastoServicos,
    this.ultimoAbastecimento,
    this.ultimoServico,
    required this.alertasAtivos,
  });

  factory DashboardVeiculo.fromJson(Map<String, dynamic> json) => DashboardVeiculo(
        veiculo: Veiculo.fromJson(json['veiculo']),
        totalAbastecimentos: json['total_abastecimentos'] ?? 0,
        totalGastoCombustivel: (json['total_gasto_combustivel'] ?? 0).toDouble(),
        totalServicos: json['total_servicos'] ?? 0,
        totalGastoServicos: (json['total_gasto_servicos'] ?? 0).toDouble(),
        ultimoAbastecimento: json['ultimo_abastecimento'] != null
            ? Abastecimento.fromJson(json['ultimo_abastecimento'])
            : null,
        ultimoServico: json['ultimo_servico'] != null
            ? Servico.fromJson(json['ultimo_servico'])
            : null,
        alertasAtivos: json['alertas_ativos'] ?? 0,
      );
}

/// Cálculo de média de consumo (km/l) entre abastecimentos consecutivos de tanque cheio
/// Fórmula: Consumo = Δkm / Litros
class CalculoConsumo {
  final Map<int, double> mediasPorId; // ID do abastecimento -> km/l
  final double? mediaGeral; // Média ponderada geral (total Δkm / total litros)
  final int totalCiclos;

  CalculoConsumo({
    required this.mediasPorId,
    this.mediaGeral,
    required this.totalCiclos,
  });

  factory CalculoConsumo.calcular(List<Abastecimento> lista) {
    if (lista.isEmpty) {
      return CalculoConsumo(mediasPorId: {}, mediaGeral: null, totalCiclos: 0);
    }

    // Ordena do menor km para o maior (ordem cronológica do odômetro)
    final ordenados = List<Abastecimento>.from(lista)
      ..sort((a, b) => a.kmNoMomento.compareTo(b.kmNoMomento));

    final Map<int, double> medias = {};
    Abastecimento? anteriorCheio;
    double totalDeltaKm = 0;
    double totalLitros = 0;
    int ciclos = 0;

    for (final abast in ordenados) {
      if (abast.tanqueCheio == 1) {
        if (anteriorCheio != null) {
          final deltaKm = abast.kmNoMomento - anteriorCheio.kmNoMomento;
          if (deltaKm > 0 && abast.litros > 0) {
            final media = deltaKm / abast.litros;
            if (abast.id != null) {
              medias[abast.id!] = media;
            }
            totalDeltaKm += deltaKm;
            totalLitros += abast.litros;
            ciclos++;
          }
        }
        anteriorCheio = abast;
      }
    }

    final double? mediaGeral = totalLitros > 0 ? (totalDeltaKm / totalLitros) : null;

    return CalculoConsumo(
      mediasPorId: medias,
      mediaGeral: mediaGeral,
      totalCiclos: ciclos,
    );
  }
}
