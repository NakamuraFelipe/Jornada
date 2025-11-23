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
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCDD2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildFiltroGrafico(),
                  _buildFiltroPeriodo(),
                  _buildFiltroSituacao(),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCDD2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(height: 300, child: _buildGrafico()),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildInfoCard(
                  title: 'Total Fechado',
                  value: '32',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildInfoCard(
                  title: 'Leads Abertos',
                  value: '15',
                  icon: Icons.email_outlined,
                  color: Colors.orange,
                ),
                _buildInfoCard(
                  title: 'Em Conexão',
                  value: '8',
                  icon: Icons.wifi,
                  color: Colors.blue,
                ),
                _buildInfoCard(
                  title: 'Total de Leads',
                  value: '55',
                  icon: Icons.people,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroGrafico() {
    return _buildDropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filtroGrafico,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ['Linha', 'Barra', 'Pizza']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Linha'
                            ? Icons.show_chart
                            : value == 'Barra'
                            ? Icons.bar_chart
                            : Icons.pie_chart,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(value),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (newValue) => setState(() => filtroGrafico = newValue!),
        ),
      ),
    );
  }

  Widget _buildFiltroPeriodo() {
    return _buildDropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filtroPeriodo,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ['Dia', 'Semana', 'Mes', 'Ano']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Dia'
                            ? Icons.today
                            : value == 'Semana'
                            ? Icons.date_range
                            : value == 'Mes'
                            ? Icons.calendar_month
                            : Icons.timeline,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(value),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (newValue) => setState(() => filtroPeriodo = newValue!),
        ),
      ),
    );
  }

  Widget _buildFiltroSituacao() {
    return _buildDropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filtroLeadSituacao,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: ['Todos', 'Em Conexão', 'Aberto', 'Fechado']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Todos'
                            ? Icons.filter_list
                            : value == 'Em Conexão'
                            ? Icons.wifi
                            : value == 'Aberto'
                            ? Icons.mark_email_unread
                            : Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(value),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (newValue) =>
              setState(() => filtroLeadSituacao = newValue!),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
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
                      colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
              );
            }).toList(),
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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
