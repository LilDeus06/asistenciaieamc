import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:amc/views/loginView.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class AttendanceDashboard extends StatefulWidget {
  final AppUser user;

  AttendanceDashboard({Key? key, required this.user}) : super(key: key);
  @override
  _AsistenciasGraficosViewState createState() => _AsistenciasGraficosViewState();
}

class _AsistenciasGraficosViewState extends State<AttendanceDashboard> {
  List<Map<String, dynamic>> asistencias = [];
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    cargarAsistencias();
  }

  Future<void> cargarAsistencias() async    {
    final QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('PROFESORES').get();

    for (var profesorDoc in profesoresSnapshot.docs) {
      final asistenciasSnapshot = await profesorDoc.reference.collection('ASISTENCIAS').get();
      asistencias.addAll(asistenciasSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>));
    }

    asistencias.sort((a, b) => DateFormat('dd-MM-yyyy').parse(a['fecha']).compareTo(DateFormat('dd-MM-yyyy').parse(b['fecha'])));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomLeft,
              colors: [Color.fromARGB(255, 0, 57, 180)!, Color.fromARGB(255, 2, 7, 32)!],
            ),
          ),
          child:SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("BIENVENIDO DIRECCION", 
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),),
                      Icon(
                        Icons.person_2_rounded,
                        color: Colors.white70,
                        size: 30,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(child: Text("MENU DE GRAFICOS", 
                style: TextStyle(
                  color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
                  )),
                ),
                const SizedBox(height: 24),
                _buildDateRangePicker(),
                const SizedBox(height: 15),
                Container(
                padding: const EdgeInsets.all(16),
                child: Center(child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Leyenda de Graficos", 
                    style: TextStyle(
                      color: Colors.white70, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 25,),
                    const Text("Falta", 
                    style: TextStyle(
                      color: Colors.white70, fontSize: 15,),
                    ),
                    const SizedBox(width: 5,),
                    Container(
                      height: 15,
                      width: 15,
                      decoration: const BoxDecoration(color: Colors.red),
                      ),
                    
                    const SizedBox(width: 20,),
                    const Text("Tardanza", 
                    style: TextStyle(
                      color: Colors.white70, fontSize: 15,),
                    ),
                    const SizedBox(width: 5,),
                    Container(
                      height: 15,
                      width: 15,
                      decoration: const BoxDecoration(color: Colors.amber),
                      ),
                  ],
                )),
                ),
                const SizedBox(height: 5),
                _buildCarouselSlider(),
                const SizedBox(height: 24),
                // _buildChartContainer(
                //   'Faltas y Tardanzas por Sección'
                //   // _buildStackedBarChart(),
                // ),
                Center(
                  child: GestureDetector(
                    child: Container(
                    padding: const EdgeInsets.all(16),
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 231, 12, 12).withOpacity(.9),
                          blurRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: const Center (child: Text("CERRAR SESION", 
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      ),
                    )),
                    ),
                  onTap: () {
                    _cerrarSesion();
                  },
                  ),
                ),
              
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => LoginPage()));// Asegúrate de tener una ruta de login configurada
  }
  
  Widget _buildDateRangePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(start: startDate, end: endDate),
                );
                if (picked != null) {
                  setState(() {
                    startDate = picked.start;
                    endDate = picked.end;
                  });
                }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                // final DateTimeRange? picked = await showDateRangePicker(
                //   context: context,
                //   firstDate: DateTime(2000),
                //   lastDate: DateTime.now(),
                //   initialDateRange: DateTimeRange(start: startDate, end: endDate),
                // );
                // if (picked != null) {
                //   setState(() {
                //     startDate = picked.start;
                //     endDate = picked.end;
                //   });
                // }
            },
              child: Text(
                '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 500,
        viewportFraction: 0.8,
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
        scrollDirection: Axis.vertical,
        autoPlay: true,
      ),
      items: [
        _buildChartContainer('Faltas y Tardanzas\n', _buildLineChart()),
        _buildChartContainer('Distribución por Curso\n', _buildPieChart()),
        _buildChartContainer('Faltas y Tardanzas por Grado y Sección\n', _buildGroupedBarChart()),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      
      padding: const EdgeInsets.only(bottom: 20, top: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max, // Añadido para minimizar el tamaño vertical
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white60),
          ),
          const SizedBox(height: 1),
          SizedBox(
            height: 280, // Altura fija para el gráfico
            child: chart,
          )
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    List<Map<String, dynamic>> filteredData = asistencias.where((a) {
      DateTime date = DateFormat('dd-MM-yyyy').parse(a['fecha']);
      return date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < filteredData.length && value.toInt() % 5 == 0) {
                  DateTime date = DateFormat('dd-MM-yyyy').parse(filteredData[value.toInt()]['fecha']);
                  return Text(
                    DateFormat('d MMM').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), 
                style: const TextStyle(color: Colors.white70, fontSize: 12));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _lineChartBarData(filteredData, 'totalFaltas', Colors.red),
          _lineChartBarData(filteredData, 'totalTardanzas', Colors.yellow),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  '${flSpot.y.toInt()}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineChartBarData(List<Map<String, dynamic>> data, String field, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value[field].toDouble());
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildPieChart() {
  Map<String, num> faltasPorCurso = {};
  Map<String, num> tardanzasPorCurso = {};
  num totalFaltas = 0;
  num totalTardanzas = 0;

  for (var item in asistencias) {
    DateTime date = DateFormat('dd-MM-yyyy').parse(item['fecha']);
    if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
      String curso = item['cursoId'];
      faltasPorCurso[curso] = (faltasPorCurso[curso] ?? 0) + item['totalFaltas'];
      tardanzasPorCurso[curso] = (tardanzasPorCurso[curso] ?? 0) + item['totalTardanzas'];
      totalFaltas += item['totalFaltas'];
      totalTardanzas += item['totalTardanzas'];
    }
  }

  return PieChart(
    PieChartData(
      sectionsSpace: 0,
      centerSpaceRadius: 40,
      sections: [
        ...faltasPorCurso.entries.map((entry) {
          double percentage = (entry.value / totalFaltas) * 100;
          return PieChartSectionData(
            color: Colors.red.withOpacity(0.9),
            value: percentage,
            title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
        ...tardanzasPorCurso.entries.map((entry) {
          double percentage = (entry.value / totalTardanzas) * 100;
          return PieChartSectionData(
            color: Colors.amber.withOpacity(0.9),
            value: percentage,
            title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
            radius: 90,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
      ],
    ),
  );
}


  Widget _buildGroupedBarChart() {
    Map<String, Map<String, num>> dataBySection = {};

    for (var item in asistencias) {
      DateTime date = DateFormat('dd-MM-yyyy').parse(item['fecha']);
      if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
        String section = item['seccionId'];
        dataBySection.putIfAbsent(section, () => {'faltas': 0, 'tardanzas': 0});
        dataBySection[section]!['faltas'] = (dataBySection[section]!['faltas'] ?? 0) + item['totalFaltas'];
        dataBySection[section]!['tardanzas'] = (dataBySection[section]!['tardanzas'] ?? 0) + item['totalTardanzas'];
      }
    }
      return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dataBySection.values.fold<double>(0, (max, data) => math.max<double>(max, (data['faltas']! + data['tardanzas']!).toDouble())),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String sectionName = dataBySection.keys.elementAt(group.x.toInt());
              String label = rodIndex == 0 ? 'Faltas' : 'Tardanzas';
              return BarTooltipItem(
                '$sectionName\n Total: ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dataBySection.length) {
                  return Text(dataBySection.keys.elementAt(value.toInt()), 
                  style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles:SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), 
                style: const TextStyle(color: Colors.white70, fontSize: 12));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: dataBySection.entries.map((entry) {
          return BarChartGroupData(
            x: dataBySection.keys.toList().indexOf(entry.key),
            barsSpace: 4,
            barRods: [  
              BarChartRodData(
                toY: entry.value['faltas']!.toDouble(),
                color: Colors.red,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: entry.value['tardanzas']!.toDouble(),
                color: Colors.yellow,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}