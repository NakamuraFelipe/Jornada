import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class DashPage extends StatefulWidget {
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  String filtroGrafico = 'Linha';
  String filtroPeriodo = 'Mes';
  String filtroLeadSituacao = 'Todos';

  List<double> gerarDados() {
    int quantidade;
    switch (filtroPeriodo) {
      case 'Dia':
        quantidade = 7;
        break;
      case 'Semana':
        quantidade = 4;
        break;
      case 'Mes':
        quantidade = 12;
        break;
      case 'Ano':
        quantidade = 5;
        break;
      default:
        quantidade = 10;
    }

    double base = filtroLeadSituacao == 'Aberto'
        ? 5
        : filtroLeadSituacao == 'Fechado'
        ? 2
        : filtroLeadSituacao == 'Em Conexão'
        ? 3
        : 4;

    Random random = Random();
    return List.generate(quantidade, (index) => base + random.nextInt(5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: filtroGrafico,
                      items: ['Linha', 'Barra', 'Pizza']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          filtroGrafico = newValue!;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: filtroPeriodo,
                      items: ['Dia', 'Semana', 'Mes', 'Ano']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          filtroPeriodo = newValue!;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: filtroLeadSituacao,
                      items: ['Todos', 'Em Conexão', 'Aberto', 'Fechado']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          filtroLeadSituacao = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(height: 300, child: _buildGrafico()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrafico() {
    List<double> dados = gerarDados();
    List<String> labels = gerarLabels();

    switch (filtroGrafico) {
      case 'Linha':
        return LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < labels.length) {
                      return Text(
                        labels[value.toInt()],
                        style: const TextStyle(fontSize: 12),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: dados
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                barWidth: 3,
                color: Colors.red,
              ),
            ],
          ),
        );

      case 'Barra':
        return BarChart(
          BarChartData(
            barGroups: dados.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    width: 16,
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < labels.length) {
                      return Text(
                        labels[value.toInt()],
                        style: const TextStyle(fontSize: 12),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
          ),
        );

      case 'Pizza':
        return PieChart(
          PieChartData(
            sections: dados.map((valor) {
              return PieChartSectionData(
                value: valor,
                color: Colors
                    .primaries[dados.indexOf(valor) % Colors.primaries.length],
                title: '${valor.toInt()}',
              );
            }).toList(),
          ),
        );

      default:
        return const Center(child: Text('Selecione um tipo de gráfico'));
    }
  }

  List<String> gerarLabels() {
    switch (filtroPeriodo) {
      case 'Dia':
        return ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      case 'Semana':
        return ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
      case 'Mes':
        return [
          'Jan',
          'Fev',
          'Mar',
          'Abr',
          'Mai',
          'Jun',
          'Jul',
          'Ago',
          'Set',
          'Out',
          'Nov',
          'Dez',
        ];
      case 'Ano':
        return ['2021', '2022', '2023', '2024', '2025'];
      default:
        return [];
    }
  }
}
