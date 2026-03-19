import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  static const String baseUrl = 'http://192.168.10.240:5000/api/dashboard';
  
  // Headers padrão
  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Buscar métricas dos cards
  static Future<Map<String, dynamic>> getMetricas({
    int? idUsuario,
    String? estado,
    String? cidade,
    String? bairro,
    String? categoria,
    String? dataInicio,
    String? dataFim,
    double? valorMin,
    double? valorMax,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (idUsuario != null) queryParams['id_usuario'] = idUsuario.toString();
      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;
      if (bairro != null && bairro != 'Todos') queryParams['bairro'] = bairro;
      if (categoria != null && categoria != 'Todas') queryParams['categoria'] = categoria;
      if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null) queryParams['data_fim'] = dataFim;
      if (valorMin != null) queryParams['valor_min'] = valorMin.toString();
      if (valorMax != null) queryParams['valor_max'] = valorMax.toString();

      final uri = Uri.parse('$baseUrl/metricas').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return data['dados'];
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar métricas');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar métricas');
      }
    } catch (e) {
      print('Erro em getMetricas: $e');
      rethrow;
    }
  }

  // Buscar dados do gráfico de evolução
  static Future<Map<String, dynamic>> getEvolucao({
    String periodo = 'Mes',
    String situacao = 'Todos',
    int? idUsuario,
    String? estado,
    String? cidade,
    String? categoria,
  }) async {
    try {
      final queryParams = <String, String>{
        'periodo': periodo,
        'situacao': situacao,
      };
      if (idUsuario != null) queryParams['id_usuario'] = idUsuario.toString();
      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;
      if (categoria != null && categoria != 'Todas') queryParams['categoria'] = categoria;

      final uri = Uri.parse('$baseUrl/evolucao').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return {
            'dados': List<double>.from(data['dados'].map((x) => x.toDouble())),
            'labels': List<String>.from(data['labels']),
          };
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar evolução');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar evolução');
      }
    } catch (e) {
      print('Erro em getEvolucao: $e');
      rethrow;
    }
  }

  // Buscar leads por bairro
  static Future<Map<String, dynamic>> getLeadsPorBairro({
    int? idUsuario,
    String? estado,
    String? cidade,
    int limit = 5,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (idUsuario != null) queryParams['id_usuario'] = idUsuario.toString();
      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;

      final uri = Uri.parse('$baseUrl/leads-por-bairro').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return {
            'leads_por_bairro': Map<String, int>.from(data['leads_por_bairro']),
            'conversao_por_bairro': Map<String, double>.from(data['conversao_por_bairro']),
          };
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar leads por bairro');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar leads por bairro');
      }
    } catch (e) {
      print('Erro em getLeadsPorBairro: $e');
      rethrow;
    }
  }

  // Buscar top consultores
  static Future<List<Map<String, dynamic>>> getTopConsultores({int limit = 5}) async {
    try {
      final uri = Uri.parse('$baseUrl/top-consultores').replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return List<Map<String, dynamic>>.from(data['consultores']);
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar top consultores');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar top consultores');
      }
    } catch (e) {
      print('Erro em getTopConsultores: $e');
      rethrow;
    }
  }

  // Buscar alertas
  static Future<Map<String, dynamic>> getAlertas({int? idUsuario}) async {
    try {
      final queryParams = <String, String>{};
      if (idUsuario != null) queryParams['id_usuario'] = idUsuario.toString();

      final uri = Uri.parse('$baseUrl/alertas').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return {
            'alertas': data['alertas'],
            'meta': data['meta'],
          };
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar alertas');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar alertas');
      }
    } catch (e) {
      print('Erro em getAlertas: $e');
      rethrow;
    }
  }

  // Buscar opções para filtros
  static Future<Map<String, dynamic>> getOpcoesFiltros() async {
    try {
      final uri = Uri.parse('$baseUrl/filtros/locais');
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return {
            'estados': List<String>.from(data['estados']),
            'cidades': data['cidades'],
            'bairros': data['bairros'],
            'categorias': List<String>.from(data['categorias']),
          };
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar opções de filtros');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar opções de filtros');
      }
    } catch (e) {
      print('Erro em getOpcoesFiltros: $e');
      rethrow;
    }
  }
}