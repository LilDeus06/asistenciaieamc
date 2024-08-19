import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amc/helpers/timezone_helper.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/views/mainView.dart';

class detailAssistancePage extends StatefulWidget {
  final String seccionId;
  final AppUser profesorId;
  final String asistenciaId;

  detailAssistancePage({
    super.key,
    required this.seccionId,
    required this.profesorId,
    required this.asistenciaId,
  });

  @override
  State<detailAssistancePage> createState() => _detailAssistancePageState();
}

class _detailAssistancePageState extends State<detailAssistancePage> {
  Map<String, dynamic>? _profesorData;
  Map<String, dynamic>? _asistenciaData;
  List<Map<String, dynamic>> _detalleAlumnas = [];
  bool _isLoading = true;
  bool _showFirstIcon = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    TimeZoneHelper.initializeTimeZones();
    _fetchDatosAsistencia();
    _timer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
      _toggleIcon();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleIcon() {
    if (mounted) {
      setState(() {
        _showFirstIcon = !_showFirstIcon;
      });
    }
  }

  Future<void> _fetchDatosAsistencia() async {
  try {
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId.dni)
        .get();

    if (!profesorDoc.exists) {
      // Si no encuentra en PROFESORES, busca en AUXILIARES
      profesorDoc = await FirebaseFirestore.instance
          .collection('AUXILIARES')
          .doc(widget.profesorId.dni)
          .get();
    }

    if (profesorDoc.exists) {
      setState(() {
        _profesorData = profesorDoc.data() as Map<String, dynamic>;
      });

      DocumentSnapshot asistenciaDoc = await profesorDoc.reference
          .collection('ASISTENCIAS')
          .doc(widget.asistenciaId)
          .get();

      if (asistenciaDoc.exists) {
        setState(() {
          _asistenciaData = asistenciaDoc.data() as Map<String, dynamic>;
        });

        QuerySnapshot detalleSnapshot = await asistenciaDoc.reference
            .collection('DETALLES')
            .orderBy('apellido_paterno')
            .orderBy('apellido_materno')
            .get();

        setState(() {
          _detalleAlumnas = detalleSnapshot.docs.map((doc) {
            return {
              'nombre': doc['nombre'],
              'apellido_paterno': doc['apellido_paterno'],
              'apellido_materno': doc['apellido_materno'],
              'estado': doc['estado'],
              'fecha': doc['fecha'],
              'hora': doc['hora'],
            };
          }).toList();
        });
      }
    }
  } catch (e) {
    print('Error al obtener los datos de asistencia: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  Icon _getEstadoIcon(String estado) {
    switch (estado) {
      case 'asistencia':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'falta':
        return const Icon(Icons.remove_circle, color: Colors.red);
      case 'tardanza':
        return const Icon(Icons.access_time_filled, color: Colors.yellow);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    TextStyle texto1 = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    TextStyle texto2 = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                height: screenHeight,
                width: screenWidth,
                color: fondo2,
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _asistenciaData == null
                    ? const Center(child: Text('No se encontraron datos de asistencia'))
                    : Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 165,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                  color: fondo1,
                                  borderRadius:
                                      const BorderRadius.all(Radius.circular(20))),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  children: [

                                    Column(

                                      children: [
                                        
                                        Text(
                                                'CURSO: ${_asistenciaData?['cursoId'] ?? 'N/A'}',
                                                style: texto1),
                                        const SizedBox(height: 10,),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.group,
                                              color: whiteColor,
                                            ),
                                            Text(
                                                '${_asistenciaData?['totalAlumnas'] ?? 'N/A'}',
                                                style: texto1),
                                            const SizedBox(
                                              width: 30,
                                            ),
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                            Text(
                                                '${_asistenciaData?['totalAsistencias'] ?? 'N/A'}',
                                                style: texto1),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            Text(
                                                '${_asistenciaData?['totalFaltas'] ?? 'N/A'}',
                                                style: texto1),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Icon(
                                              Icons.access_time_filled,
                                              color: Colors.yellow,
                                            ),
                                            Text(
                                                '${_asistenciaData?['totalTardanzas'] ?? 'N/A'}',
                                                style: texto1),
                  
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Icon(
                                              Icons.playlist_add_check_circle_sharp,
                                              color: Colors.white70,
                                            ),
                                            Text(
                                                '${_asistenciaData?['totalJustificaciones'] ?? 'N/A'}',
                                                style: texto1),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            
                                            Text(
                                                'Grado: ${widget.seccionId.substring(1, 2)}',
                                                style: texto1),
                                            Text(
                                                'Sección: ${widget.seccionId.substring(2, 3)}',
                                                style: texto1),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_month,
                                                  color: whiteColor,
                                                ),
                                                Text(
                                                    '${_asistenciaData?['fecha'] ?? 'N/A'}',
                                                    style: texto1),
                                              ],
                                            ),
                                            // Text(
                                            //     '${_asistenciaData?['hora'] ?? 'N/A'}',
                                            //     style: texto1),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                    color: fondo1,
                                    borderRadius:
                                        const BorderRadius.all(Radius.circular(20))),
                                child: ListView.builder(
                                  itemCount: _detalleAlumnas.length,
                                  itemBuilder: (context, index) {
                                    final alumna = _detalleAlumnas[index];
                                    return ListTile(
                                      title: Text(
                                        '${alumna['apellido_paterno']} ${alumna['apellido_materno']}, ${alumna['nombre']}',
                                        style: texto2,
                                      ),
                                      trailing: Container(
                                        width: screenWidth * 0.1,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (alumna['estado'] == 'falta justificada')
                                              AnimatedSwitcher(
                                                  duration: const Duration(seconds: 1),
                                                  child: _showFirstIcon
                                                      ? const Icon(
                                                          Icons.remove_circle,
                                                          key: ValueKey(1),
                                                          color: Colors.red,
                                                        )
                                                      : const Icon(
                                                          Icons
                                                              .playlist_add_check_circle_rounded,
                                                          key: ValueKey(2),
                                                          color: Color.fromARGB(
                                                              255, 221, 221, 221),
                                                        ))
                                            else if (alumna['estado'] ==
                                                'tardanza justificada')
                                              AnimatedSwitcher(
                                                  duration: const Duration(seconds: 1),
                                                  child: _showFirstIcon
                                                      ? const Icon(
                                                          Icons.access_time_filled,
                                                          key: ValueKey(1),
                                                          color: Colors.yellow,
                                                        )
                                                      : const Icon(
                                                          Icons
                                                              .playlist_add_check_circle_rounded,
                                                          key: ValueKey(2),
                                                          color: Color.fromARGB(
                                                              255, 221, 221, 221),
                                                        ))
                                            else if (alumna['estado'] !=
                                                    'falta justificada' ||
                                                alumna['estado'] != 'tardanza justificada')
                                              _getEstadoIcon(alumna['estado'])
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
