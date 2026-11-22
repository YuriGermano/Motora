import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// ApiService — camada de comunicação com a API Motora
/// Centraliza todas as requisições HTTP do app
class ApiService {
  // IP do seu computador na rede Wi-Fi (detectado automaticamente: 192.168.0.105)
  static const String baseUrl = 'http://192.168.0.105:8000';

  // Timeout padrão para requisições
  static const Duration _timeout = Duration(seconds: 10);

  // Headers padrão
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─────────────────────── HEALTH CHECK ───────────────────────

  /// Verifica se a API está disponível
  static Future<bool> isApiOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────── VEÍCULOS ───────────────────────

  static Future<List<Veiculo>> getVeiculos() async {
    final response = await http
        .get(Uri.parse('$baseUrl/veiculos'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Veiculo.fromJson(e)).toList();
  }

  static Future<Veiculo> getVeiculo(int id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/veiculos/$id'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
    return Veiculo.fromJson(jsonDecode(response.body));
  }

  static Future<Veiculo> criarVeiculo(Veiculo veiculo) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/veiculos'),
          headers: _headers,
          body: jsonEncode(veiculo.toJson()),
        )
        .timeout(_timeout);
    _checkResponse(response);
    return Veiculo.fromJson(jsonDecode(response.body));
  }

  static Future<Veiculo> atualizarVeiculo(int id, Map<String, dynamic> dados) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/veiculos/$id'),
          headers: _headers,
          body: jsonEncode(dados),
        )
        .timeout(_timeout);
    _checkResponse(response);
    return Veiculo.fromJson(jsonDecode(response.body));
  }

  static Future<void> excluirVeiculo(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/veiculos/$id'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
  }

  static Future<DashboardVeiculo> getDashboard(int veiculoId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/veiculos/$veiculoId/dashboard'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
    return DashboardVeiculo.fromJson(jsonDecode(response.body));
  }

  // ─────────────────────── ABASTECIMENTOS ───────────────────────

  static Future<List<Abastecimento>> getAbastecimentos(int veiculoId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/abastecimentos/veiculo/$veiculoId'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Abastecimento.fromJson(e)).toList();
  }

  static Future<Abastecimento> registrarAbastecimento(Abastecimento abastecimento) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/abastecimentos'),
          headers: _headers,
          body: jsonEncode(abastecimento.toJson()),
        )
        .timeout(_timeout);
    _checkResponse(response);
    return Abastecimento.fromJson(jsonDecode(response.body));
  }

  static Future<void> excluirAbastecimento(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/abastecimentos/$id'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
  }

  // ─────────────────────── SERVIÇOS ───────────────────────

  static Future<List<Servico>> getServicos(int veiculoId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/servicos/veiculo/$veiculoId'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Servico.fromJson(e)).toList();
  }

  static Future<Servico> registrarServico(Servico servico) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/servicos'),
          headers: _headers,
          body: jsonEncode(servico.toJson()),
        )
        .timeout(_timeout);
    _checkResponse(response);
    return Servico.fromJson(jsonDecode(response.body));
  }

  static Future<void> excluirServico(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/servicos/$id'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
  }

  // ─────────────────────── ALERTAS ───────────────────────

  static Future<List<Alerta>> getAlertas(int veiculoId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/alertas/veiculo/$veiculoId'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Alerta.fromJson(e)).toList();
  }

  static Future<Alerta> criarAlerta(Alerta alerta) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/alertas'),
          headers: _headers,
          body: jsonEncode(alerta.toJson()),
        )
        .timeout(_timeout);
    _checkResponse(response);
    return Alerta.fromJson(jsonDecode(response.body));
  }

  static Future<void> excluirAlerta(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/alertas/$id'), headers: _headers)
        .timeout(_timeout);
    _checkResponse(response);
  }

  // ─────────────────────── HELPER PRIVADO ───────────────────────

  /// Verifica o status code da resposta e lança exceção com mensagem clara
  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String mensagem;
    try {
      final body = jsonDecode(response.body);
      mensagem = body['detail'] ?? 'Erro desconhecido';
    } catch (_) {
      mensagem = 'Erro ${response.statusCode}';
    }
    throw ApiException(response.statusCode, mensagem);
  }
}

/// Exceção personalizada da API com statusCode e mensagem
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
