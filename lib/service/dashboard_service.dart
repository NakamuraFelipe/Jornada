import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:teste/constants.dart';

class DashboardService {
  static String get baseUrl => '$kBaseUrl/api/dashboard';

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== MÉTODOS PRINCIPAIS ====================

  // Buscar métricas dos cards
  static Future<Map<String, dynamic>> getMetricas({
    required String token,
    List<int>? idsUsuario,
    String? estado,
    String? cidade,
    String? bairro,
    String? categoria,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (idsUsuario != null && idsUsuario.isNotEmpty) {
        for (var id in idsUsuario) {
          queryParams['id_usuario'] = id.toString();
        }
      }

      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;
      if (bairro != null && bairro != 'Todos') queryParams['bairro'] = bairro;
      if (categoria != null && categoria != 'Todas')
        queryParams['categoria'] = categoria;
      if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null) queryParams['data_fim'] = dataFim;

      final uri = Uri.parse(
        '$baseUrl/metricas',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Métricas: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          if (data['status'] == 'ok') {
            if (data['dados'] is Map<String, dynamic>) {
              return Map<String, dynamic>.from(data['dados']);
            } else {
              print('Erro: campo "dados" não é um Map');
              return _getMetricasPadrao();
            }
          } else {
            throw Exception(data['mensagem'] ?? 'Erro ao buscar métricas');
          }
        } else {
          print('Erro: resposta não é um Map');
          return _getMetricasPadrao();
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar métricas');
      }
    } catch (e) {
      print('Erro em getMetricas: $e');
      return _getMetricasPadrao();
    }
  }

  static Map<String, dynamic> _getMetricasPadrao() {
    return {
      'fechado': 0,
      'abertos': 0,
      'conexao': 0,
      'negociacao': 0,
      'total': 0,
      'conversao': 0,
      'cobertura': 0,
      'variacao_fechados': 0,
      'leads_ano_atual': 0,
    };
  }

  // Buscar dados do gráfico de evolução
  static Future<Map<String, dynamic>> getEvolucao({
    required String token,
    String periodo = 'Mes',
    String situacao = 'Todos',
    List<int>? idsUsuario,
    String? estado,
    String? cidade,
    String? categoria,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{
        'periodo': periodo,
        'situacao': situacao,
      };

      if (idsUsuario != null && idsUsuario.isNotEmpty) {
        for (var id in idsUsuario) {
          queryParams['id_usuario'] = id.toString();
        }
      }

      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;
      if (categoria != null && categoria != 'Todas')
        queryParams['categoria'] = categoria;
      if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null) queryParams['data_fim'] = dataFim;

      final uri = Uri.parse(
        '$baseUrl/evolucao',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Evolução: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return {
            'dados': data['dados'] is List
                ? List<double>.from(
                    data['dados'].map((x) => (x as num).toDouble()),
                  )
                : [],
            'labels': data['labels'] is List
                ? List<String>.from(data['labels'])
                : [],
          };
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar evolução');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar evolução');
      }
    } catch (e) {
      print('Erro em getEvolucao: $e');
      return {'dados': [], 'labels': []};
    }
  }

  // Buscar leads por bairro
  static Future<Map<String, dynamic>> getLeadsPorBairro({
    required String token,
    List<int>? idsUsuario,
    String? estado,
    String? cidade,
    int limit = 5,
  }) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};

      if (idsUsuario != null && idsUsuario.isNotEmpty) {
        for (var id in idsUsuario) {
          queryParams['id_usuario'] = id.toString();
        }
      }

      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;

      final uri = Uri.parse(
        '$baseUrl/leads-por-bairro',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Leads por Bairro: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return {
            'leads_por_bairro': data['leads_por_bairro'] is Map
                ? Map<String, int>.from(data['leads_por_bairro'])
                : {},
            'conversao_por_bairro': data['conversao_por_bairro'] is Map
                ? Map<String, double>.from(data['conversao_por_bairro'])
                : {},
          };
        } else {
          throw Exception(
            data['mensagem'] ?? 'Erro ao buscar leads por bairro',
          );
        }
      } else {
        throw Exception(
          'Erro ${response.statusCode} ao buscar leads por bairro',
        );
      }
    } catch (e) {
      print('Erro em getLeadsPorBairro: $e');
      return {'leads_por_bairro': {}, 'conversao_por_bairro': {}};
    }
  }

  // Buscar top consultores
  static Future<List<Map<String, dynamic>>> getTopConsultores({
    required String token,
    int limit = 5,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/top-consultores',
      ).replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri, headers: _headers(token));

      print('GET Top Consultores: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return data['consultores'] is List
              ? List<Map<String, dynamic>>.from(data['consultores'])
              : [];
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar top consultores');
        }
      } else {
        throw Exception(
          'Erro ${response.statusCode} ao buscar top consultores',
        );
      }
    } catch (e) {
      print('Erro em getTopConsultores: $e');
      return [];
    }
  }

  // Buscar alertas
  static Future<Map<String, dynamic>> getAlertas({
    required String token,
    List<int>? idsUsuario,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (idsUsuario != null && idsUsuario.isNotEmpty) {
        for (var id in idsUsuario) {
          queryParams['id_usuario'] = id.toString();
        }
      }

      final uri = Uri.parse(
        '$baseUrl/alertas',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Alertas: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return {
            'alertas': data['alertas'] is List ? data['alertas'] : [],
            'meta': data['meta'] is Map ? data['meta'] : {},
          };
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar alertas');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar alertas');
      }
    } catch (e) {
      print('Erro em getAlertas: $e');
      return {'alertas': [], 'meta': {}};
    }
  }

  // Buscar opções para filtros
  static Future<Map<String, dynamic>> getOpcoesFiltros({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/filtros/locais');
      final response = await http.get(uri, headers: _headers(token));

      print('GET Opções Filtros: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return {
            'estados': data['estados'] is List
                ? List<String>.from(data['estados'])
                : ['Todos'],
            'cidades': data['cidades'] is List ? data['cidades'] : [],
            'bairros': data['bairros'] is List ? data['bairros'] : [],
            'categorias': data['categorias'] is List
                ? List<String>.from(data['categorias'])
                : ['Todas'],
          };
        } else {
          throw Exception(
            data['mensagem'] ?? 'Erro ao buscar opções de filtros',
          );
        }
      } else {
        throw Exception(
          'Erro ${response.statusCode} ao buscar opções de filtros',
        );
      }
    } catch (e) {
      print('Erro em getOpcoesFiltros: $e');
      return {
        'estados': ['Todos'],
        'cidades': [],
        'bairros': [],
        'categorias': ['Todas'],
      };
    }
  }

  // ==================== NOVOS MÉTODOS ====================

  // Buscar cancelamentos
  static Future<List<Map<String, dynamic>>> getCancelamentos({
    required String token,
    String? estado,
    String? cidade,
    String? bairro,
    String groupBy = 'bairro',
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{'group_by': groupBy};
      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;
      if (bairro != null && bairro != 'Todos') queryParams['bairro'] = bairro;
      if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null) queryParams['data_fim'] = dataFim;

      final uri = Uri.parse(
        '$baseUrl/cancelamentos',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Cancelamentos: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return data['cancelamentos'] is List
              ? List<Map<String, dynamic>>.from(data['cancelamentos'])
              : [];
        } else {
          throw Exception(data['mensagem'] ?? 'Erro ao buscar cancelamentos');
        }
      } else {
        throw Exception('Erro ${response.statusCode} ao buscar cancelamentos');
      }
    } catch (e) {
      print('Erro em getCancelamentos: $e');
      return [];
    }
  }

  // Buscar ranking de vendas
  static Future<List<Map<String, dynamic>>> getRankingVendas({
    required String token,
    String? estado,
    String? cidade,
    String? bairro,
    String? categoria,
    String? dataInicio,
    String? dataFim,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{'limit': limit.toString()};
      if (estado != null && estado != 'Todos') queryParams['estado'] = estado;
      if (cidade != null && cidade != 'Todas') queryParams['cidade'] = cidade;
      if (bairro != null && bairro != 'Todos') queryParams['bairro'] = bairro;
      if (categoria != null && categoria != 'Todas')
        queryParams['categoria'] = categoria;
      if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null) queryParams['data_fim'] = dataFim;

      final uri = Uri.parse(
        '$baseUrl/ranking-vendas',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Ranking Vendas: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return data['ranking'] is List
              ? List<Map<String, dynamic>>.from(data['ranking'])
              : [];
        } else {
          throw Exception(
            data['mensagem'] ?? 'Erro ao buscar ranking de vendas',
          );
        }
      } else {
        throw Exception(
          'Erro ${response.statusCode} ao buscar ranking de vendas',
        );
      }
    } catch (e) {
      print('Erro em getRankingVendas: $e');
      return [];
    }
  }

  // Buscar desempenho de consultores

  static Future<List<Map<String, dynamic>>> getDesempenhoConsultores({
    required String token,
    required List<int> idsUsuario,
    String? estado,
    String? cidade,
    String? bairro,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      // Constrói a URL manualmente para permitir múltiplos id_usuario
      final buffer = StringBuffer('$baseUrl/desempenho-consultores?');

      // Adiciona cada id_usuario como parâmetro separado
      for (var id in idsUsuario) {
        buffer.write('id_usuario=$id&');
      }

      if (estado != null && estado != 'Todos')
        buffer.write('estado=${Uri.encodeComponent(estado)}&');
      if (cidade != null && cidade != 'Todas')
        buffer.write('cidade=${Uri.encodeComponent(cidade)}&');
      if (bairro != null && bairro != 'Todos')
        buffer.write('bairro=${Uri.encodeComponent(bairro)}&');
      if (dataInicio != null) buffer.write('data_inicio=$dataInicio&');
      if (dataFim != null) buffer.write('data_fim=$dataFim&');

      // Remove o último '&' se existir
      String url = buffer.toString();
      if (url.endsWith('&')) url = url.substring(0, url.length - 1);

      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: _headers(token));

      print('GET Desempenho Consultores: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return data['desempenho'] is List
              ? List<Map<String, dynamic>>.from(data['desempenho'])
              : [];
        } else {
          throw Exception(
            data['mensagem'] ?? 'Erro ao buscar desempenho dos consultores',
          );
        }
      } else {
        throw Exception(
          'Erro ${response.statusCode} ao buscar desempenho dos consultores',
        );
      }
    } catch (e) {
      print('Erro em getDesempenhoConsultores: $e');
      return [];
    }
  }

  // Buscar lista de consultores
  static Future<List<Map<String, dynamic>>> getListaConsultores({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/consultores');
      final response = await http.get(uri, headers: _headers(token));

      print('GET Lista Consultores: $uri');
      print('Status: ${response.statusCode}');
      print('Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['status'] == 'ok') {
          return data['usuarios'] is List
              ? List<Map<String, dynamic>>.from(data['usuarios'])
              : [];
        } else {
          print('Erro no formato da resposta');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('Endpoint de consultores não encontrado (404)');
        return [];
      } else {
        print('Erro ${response.statusCode} ao buscar lista de consultores');
        return [];
      }
    } catch (e) {
      print('Erro em getListaConsultores: $e');
      return [];
    }
  }
}
