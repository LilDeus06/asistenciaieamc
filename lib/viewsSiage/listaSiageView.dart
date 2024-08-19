import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:amc/views/mainView.dart';
import 'package:amc/helpers/timezone_helper.dart';
import 'package:timezone/timezone.dart' as tz;

class AlumnadoSalonView extends StatefulWidget {
  final String seccionId;
  final String seccionNombre;
  final String gradoNombre;
  final String profesorId;  // Añadimos el ID del profesor

  AlumnadoSalonView({
    required this.seccionId,
    required this.seccionNombre,
    required this.gradoNombre,
    required this.profesorId,  // Añadimos el ID del profesor
  });

  @override
  _AlumnadoSalonViewState createState() => _AlumnadoSalonViewState();
}

class _AlumnadoSalonViewState extends State<AlumnadoSalonView> {
  List<Map<String, dynamic>> _alumnas = [];
  int _totalAlumnas = 0;
  TextStyle texto = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _fetchAlumnas();
    //_fetchCursoNombre();  // Llamamos a la función para obtener el nombre del curso
  }

  void _fetchAlumnas() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('ALUMNAS')
        .where('seccionId', isEqualTo: widget.seccionId)
        .orderBy('apellido_paterno')
        .get();

    List<Map<String, dynamic>> alumnas = querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'nombre': doc['nombre'],
        'apellido_paterno': doc['apellido_paterno'],
        'apellido_materno': doc['apellido_materno'],
      };
    }).toList();

    setState(() {
      _alumnas = alumnas;
      _totalAlumnas = alumnas.length; // Inicialmente no contamos asistencia, faltas ni tardanzas
    });
  }
  void _todasAsistentes(){
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return SafeArea(
      child: Scaffold(
        /* appBar: AppBar(
          title: Text('Alumnado del ${widget.gradoNombre} - ${widget.seccionNombre}',style: const TextStyle(
            color: Colors.white,
            fontSize: 20),),
          backgroundColor: fondo2,
          iconTheme: const IconThemeData(
            color: Colors.white
          ),
        ), */
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                color: fondo2,
                width: screenWidth,
                height: screenHeight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: screenWidth ,
                    height: screenHeight * 0.15,
                    decoration:  BoxDecoration(
                      color: fondo1,
                      borderRadius:  const BorderRadius.all(Radius.circular(20))
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('TOTAL', style: texto),
                                  const SizedBox(height: 10,),
                                  Row(
                                    children: [
                                      const Icon(Icons.group, color: Colors.white,),
                                      const SizedBox(width: 10,),
                                      Text(_totalAlumnas.toString(), style: texto,),
                                    ],
                                  )
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(DateFormat('dd-MM-yyyy').format(TimeZoneHelper.nowInLima()), style: texto),
                                      const SizedBox(width: 10,),
                                      const Icon(Icons.calendar_month, color: Colors.white, size: 30,),
                                    ],
                                  ),
                                  Text('Grado: ${widget.seccionId.substring(1,2)}',style: texto,),
                                  const SizedBox(width: 10,),
                                  Text('Sección: ${widget.seccionId.substring(2,3)}',style: texto,),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      width: screenWidth * 0.9,
                      decoration:  BoxDecoration(
                        color: fondo1,
                        borderRadius: const BorderRadius.all(Radius.circular(30))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: ListView.builder(
                          itemCount: _alumnas.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                '${_alumnas[index]['id']}, ${ _alumnas[index]['apellido_paterno']} ${_alumnas[index]['apellido_materno']}, ${_alumnas[index]['nombre']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              
                            );
                          },
                          
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
