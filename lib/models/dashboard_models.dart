import 'package:flutter/material.dart';

class MetricaCard {
  final String titulo;
  final String valor;
  final String variacao;
  final IconData icone;
  final Color cor;

  MetricaCard({
    required this.titulo,
    required this.valor,
    required this.variacao,
    required this.icone,
    required this.cor,
  });

  factory MetricaCard.fromApi(Map<String, dynamic> data, String tipo) {
    switch (tipo) {
      case 'fechado':
        return MetricaCard(
          titulo: 'Fechados',
          valor: data['fechado'].toString(),
          variacao: '${data['variacao_fechados'] > 0 ? '+' : ''}${data['variacao_fechados']}%',
          icone: Icons.check_circle,
          cor: Colors.green,
        );
      case 'abertos':
        return MetricaCard(
          titulo: 'Abertos',
          valor: data['abertos'].toString(),
          variacao: '+8%', // Calcular variação real depois
          icone: Icons.email_outlined,
          cor: Colors.orange,
        );
      case 'conversao':
        return MetricaCard(
          titulo: 'Conversão',
          valor: '${data['conversao']}%',
          variacao: '+2%', // Calcular variação real depois
          icone: Icons.trending_up,
          cor: Colors.blue,
        );
      case 'cobertura':
        return MetricaCard(
          titulo: 'Cobertura',
          valor: '${data['cobertura']}%',
          variacao: '+5%', // Calcular variação real depois
          icone: Icons.map,
          cor: Colors.purple,
        );
      default:
        throw Exception('Tipo de métrica inválido');
    }
  }
}

class Alerta {
  final String tipo;
  final String icone;
  final String cor;
  final String mensagem;

  Alerta({
    required this.tipo,
    required this.icone,
    required this.cor,
    required this.mensagem,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      tipo: json['tipo'],
      icone: json['icone'],
      cor: json['cor'],
      mensagem: json['mensagem'],
    );
  }

  Color getColor() {
    switch (cor) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData getIconData() {
    switch (icone) {
      case 'warning':
        return Icons.warning_amber;
      case 'access_time':
        return Icons.access_time;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }
}