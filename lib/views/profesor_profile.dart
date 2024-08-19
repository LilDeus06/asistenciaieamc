import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:amc/views/detailAssistance.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/widgets/Icono.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:amc/helpers/timezone_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfesorProfile extends StatefulWidget {
  final AppUser profesorId;

  const ProfesorProfile({Key? key, required this.profesorId}) : super(key: key);

  @override
  _ProfesorProfileState createState() => _ProfesorProfileState();
}

class _ProfesorProfileState extends State<ProfesorProfile> {
  Map<String, dynamic>? _profesorData;
  // ignore: unused_field
  String _currentDate = '';
  String cursoId = '';
  // ignore: unused_field
  List<dynamic> _seccionData = [];
  Map<String, dynamic>? _cursoData;
  List<Map<String, dynamic>> _asistencias = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;
  

  @override
  void initState() {
    super.initState();
    TimeZoneHelper.initializeTimeZones();
    _currentDate = DateFormat('dd-MM-yyyy').format(TimeZoneHelper.nowInLima());
    _fetchProfesorData();
    _loadAsistencias().then((asistencias) {
      setState(() {
        _asistencias = asistencias;
        _isFirstLoad = false;
      });
    });
  }

  void _fetchProfesorData() async {
  try {
    // Obtener el documento del profesor
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId.dni)
        .get();

    if (!profesorDoc.exists) {
      print('El documento del profesor no existe.');
      return;
    }

    print('Profesor Data: ${profesorDoc.data()}');

    // Actualizar el estado con los datos del profesor
    setState(() {
      _profesorData = profesorDoc.data() as Map<String, dynamic>;
      cursoId = profesorDoc['cursoId'];
    });

    // Obtener el documento del curso
    DocumentSnapshot<Map<String, dynamic>> nombreCurso = await FirebaseFirestore
        .instance
        .collection('CURSOS')
        .doc(cursoId)
        .get();

    if (!nombreCurso.exists) {
      print('El documento del curso no existe.');
      return;
    }

    print('Curso Data: ${nombreCurso.data()}');

    // Actualizar el estado con los datos del curso
    setState(() {
      _cursoData = nombreCurso.data();
    });

    // Obtener las secciones desde la subcolección SECCIONES
    QuerySnapshot seccionesSnapshot = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId.dni)                              
        .collection('SECCIONES')
        .get();

    if (seccionesSnapshot.docs.isEmpty) {
      print('No se encontraron secciones.');
    } else {
      // Convertir los documentos de la subcolección en una lista de mapas
      List<Map<String, dynamic>> seccionesData = seccionesSnapshot.docs.map((doc) {
        //print('Sección ID: ${doc.id}');       //AQUI IMPRIME LAS SECCIONES QUE SON ID
        //print('Sección Data: ${doc.data()}');   //AQUI IMPRIME DENTRO DE LAS SECCIONES QUE CAMPOS TIENE
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Actualizar el estado con los datos de las secciones
      setState(() {
        _seccionData = seccionesData;
      });

      //print('Secciones Data: $_seccionData'); //AQUI IMPRIME LO QUE SON DENTRO DE LOS CAMPOS QUE HAY DENTRO
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}

  Future<List<Map<String, dynamic>>> _loadAsistencias() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? asistenciasString = prefs.getStringList('asistencias');
    if (asistenciasString != null) {
      return asistenciasString.map((asistencia) {
        Map<String, dynamic> asistenciaMap = jsonDecode(asistencia) as Map<String, dynamic>;
        // Convertir cadenas de texto a DateTime si es necesario
        if (asistenciaMap['fecha'] is String) {
          asistenciaMap['fecha'] = DateFormat('dd-MM-yyyy').parse(asistenciaMap['fecha']);
        }
        return asistenciaMap;
      }).toList();
    }
    return [];
  }

  Future<void> _saveAsistencias(List<Map<String, dynamic>> asistencias) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> asistenciasString = asistencias.map((asistencia) {
      Map<String, dynamic> asistenciaMap = Map.from(asistencia);

      
      // Convertir DateTime a cadena de texto
      if (asistenciaMap['fecha'] is DateTime) {
        asistenciaMap['fecha'] = DateFormat('dd-MM-yyyy').format(asistenciaMap['fecha']);
      }
      return jsonEncode(asistenciaMap);
    }).toList();
    await prefs.setStringList('asistencias', asistenciasString);
  }

  void _deleteAsistencia(int index) async {
    var asistencia = _asistencias[index];
    setState(() {
      _asistencias.removeAt(index);
    });

      // Obtener el ID del documento de asistencia
  String asistenciaId = asistencia['id'];

  // Eliminar asistencia de Firestore
  DocumentReference asistenciaDocRef = FirebaseFirestore.instance
      .collection('PROFESORES')
      .doc(widget.profesorId.dni)
      .collection('ASISTENCIAS')
      .doc(asistenciaId);

  // Eliminar todos los detalles de la asistencia
  QuerySnapshot detallesSnapshot = await asistenciaDocRef.collection('DETALLES').get();
  for (var doc in detallesSnapshot.docs) {
    await doc.reference.delete();
  }

  // Eliminar el documento de asistencia
  await asistenciaDocRef.delete();

  // Eliminar asistencia de SharedPreferences
  List<Map<String, dynamic>> asistencias = await _loadAsistencias();
  asistencias.removeWhere((a) => a['id'] == asistenciaId);
  await _saveAsistencias(asistencias);
  }





  Future<void> _exportarPDF() async {
  if (_selectedAsistencia == null) {
    print('No se ha seleccionado ninguna asistencia para imprimir');
    return;
  }

  final pdf = pw.Document();
  final font = await PdfGoogleFonts.nunitoExtraLight();

  String asistenciaId = _selectedAsistencia!['id'] ?? '';// Asumiendo que _selectedAsistencia es un DocumentSnapshot
  String seccionId = _selectedAsistencia!['seccionId'] ?? '';
  String cursoId = _selectedAsistencia!['cursoId'] ?? '';
  String fecha = _selectedAsistencia!['fecha'] ?? '';
  String hora = _selectedAsistencia!['hora'] ?? '';

  // Obtener el nombre del profesor
  // ignore: unused_local_variable
  String profesorId = FirebaseAuth.instance.currentUser!.uid;
  DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
      .collection('PROFESORES')
      .doc(widget.profesorId.dni)
      .get();

  String nombreProfesor = 'Nombre no disponible';

  if (profesorDoc.exists) {
    Map<String, dynamic>? profesorData = profesorDoc.data() as Map<String, dynamic>?;
    if (profesorData != null) {
      nombreProfesor = '${profesorData['nombre'] ?? ''} ${profesorData['apellido_paterno'] ?? ''} ${profesorData['apellido_materno'] ?? ''}';
    }
  } else {
    print('No se encontró el documento del profesor');
  }
  
  List<pw.TableRow> rows = [
    pw.TableRow(
      children: [
        'Apellido Paterno', 'Apellido Materno', 'Nombre', 'Estado'
      ].map((header) => pw.Padding(
        padding: pw.EdgeInsets.only(left: 5),
        child: pw.Text(header, 
          style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold)
        ),
      )).toList(),
    )
  ];

  try {
    QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS')
        .doc(asistenciaId)
        .collection('DETALLES')
        .get();

    List<Map<String, dynamic>> alumnas = detallesSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Ordenar alumnas alfabéticamente
    alumnas.sort((a, b) {
      int compare = (a['apellido_paterno'] ?? '').compareTo(b['apellido_paterno'] ?? '');
      if (compare == 0) {
        compare = (a['apellido_materno'] ?? '').compareTo(b['apellido_materno'] ?? '');
      }
      if (compare == 0) {
        compare = (a['nombre'] ?? '').compareTo(b['nombre'] ?? '');
      }
      return compare;
    });

    for (var alumna in alumnas) {
      rows.add(pw.TableRow(
        children: [
          'apellido_paterno', 'apellido_materno', 'nombre', 'estado'
        ].map((field) => pw.Padding(
          padding: pw.EdgeInsets.only(left: 5),
          child: pw.Text(alumna[field] ?? '', 
            style: pw.TextStyle(font: font, fontSize: 10)
          ),
        )).toList(),
      ));
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fecha: $fecha   Hora: $hora', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Profesor: $nombreProfesor', style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Grado: ${seccionId.substring(1, 2)} Sección: ${seccionId.substring(2, 3)}', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Curso: $cursoId', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: rows,
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    if (bytes.isNotEmpty) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'reporte_asistencia_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}_$cursoId''_$seccionId.pdf',
      );
      print('PDF compartido exitosamente');
    } else {
      print('Error: El PDF generado está vacío');
    }
  } catch (e) {
    print('Error al generar el PDF: $e');
  }
}

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => LoginPage()));// Asegúrate de tener una ruta de login configurada
  }

  Future<void> _fetchAsistenciasFromFirebase() async {
    setState(() {
      _isLoading = true;
    });

    CollectionReference asistenciasRef = FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS');

    QuerySnapshot querySnapshot = await asistenciasRef.get();
    List<Map<String, dynamic>> asistencias = [];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> asistencia = doc.data() as Map<String, dynamic>;
        asistencia['id'] = doc.id; // Agregar el ID del documento
      // Convertir Timestamp a cadena de texto
      if (asistencia['fecha'] is Timestamp) {
        asistencia['fecha'] = DateFormat('dd-MM-yyyy').format((asistencia['fecha'] as Timestamp).toDate());
      }

      // Obtener la subcolección DETALLES
      CollectionReference detallesRef = doc.reference.collection('DETALLES');
      QuerySnapshot detallesSnapshot = await detallesRef.get();
      List<Map<String, dynamic>> detalles = detallesSnapshot.docs.map((detalleDoc) {
        return detalleDoc.data() as Map<String, dynamic>;
      }).toList();

      asistencia['detalles'] = detalles;
      asistencias.add(asistencia);
    }

    setState(() {
      _asistencias = asistencias;
      _isLoading = false;
    });

    // Guardar asistencias en SharedPreferences
    await _saveAsistencias(asistencias);
  }

  // Función auxiliar para parsear la fecha
DateTime? _parseDate(dynamic fecha) {
  if (fecha is DateTime) return fecha;
  if (fecha is Timestamp) return fecha.toDate();
  if (fecha is String) {
    try {
      return DateFormat('dd-MM-yyyy').parse(fecha);
    } catch (e) {
      print('Error parsing date: $fecha');
      return null;
    }
  }
  return null;
}

  Map<String, dynamic>? _selectedAsistencia;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    Color whiteColor = const Color(0XFFF6F6F6);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);
    Color fondoDatos = const Color(0XFF001739);
    TextStyle textoDatosProf = TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: whiteText);

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                color: fondo2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(0),
                    width: screenWidth,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: fondo1,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(' ', style: textoDatosProf),
                            Text('MI PERFIL', style: textoDatosProf),
                            GestureDetector(
                              onTap: (){_cerrarSesion();},
                              child: 
                              const Tooltip(
                                message: "CERRAR SESION",
                                child: Icon(
                                Icons.arrow_circle_right_outlined,
                                  color: Color(0XFF0066FF),
                                  size: 35.0,
                                ),
                              ),
                              
                            ),
                          ],
                        )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left:8.0),
                                  child: Text(
                                    'Nombre:',
                                    style: textoDatosProf,
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['nombre'] ?? ''}', style: textoDatosProf),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left:8.0),
                                  child: Text(
                                    'Apellido Paterno:',
                                    style: textoDatosProf,
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['apellido_paterno'] ?? ''}', style: textoDatosProf),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left:8.0),
                                  child: Text(
                                    'Apellido Materno:',
                                    style: textoDatosProf,
                                  ),
                                ),
                                Container(
                                  width: screenWidth * 0.4,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    color: fondoDatos,
                                  ),
                                  child: Text('${_profesorData?['apellido_materno'] ?? ''}', style: textoDatosProf),
                                ),
                              ],
                            ),
                            
                            Column(
                              children: <Widget>[
                                IconoPerfil(),
                                const SizedBox(height: 20),
                                Container(
                                  width: 180,
                                  child: Text(
                                    '${_cursoData?['nombre'] ?? ''}',
                                    style: textoDatosProf,textAlign:  TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: 
                    _fetchAsistenciasFromFirebase,
                    child: const Text('Cargar Asistencias'),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      height: screenHeight * 0.45,
                      width: screenWidth,
                      color: fondo2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asistencias del Día',
                            style: textoDatosProf,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : SingleChildScrollView(
                                    child: _asistencias.isEmpty
                                        ? Center(child: Text('No hay asistencias para mostrar.', style: textoDatosProf))
                                        : Column(
                                            children: _asistencias.asMap().entries.map((entry) {
                                              int index = entry.key;
                                              var asistencia = entry.value;
                                              String seccionId = asistencia['seccionId'] ?? '';
                                              return GestureDetector(
                                                onTap: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => detailAssistancePage(seccionId: seccionId, profesorId:widget.profesorId , asistenciaId: asistencia['id'],)));
                                                },
                                                child: Card(
                                                  color: fondo1,
                                                  child: Column(
                                                    children: [
                                                      ListTile(
                                                        title: Text(
                                                          'Grado: ${seccionId.isNotEmpty ? seccionId.substring(1, 2) : 'N/A'} Sección: ${seccionId.isNotEmpty ? seccionId.substring(2, 3) : 'N/A'}',
                                                          style: textoDatosProf,
                                                        ),
                                                        subtitle: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                
                                                              children: [
                                                                const Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons.calendar_month,
                                                                      color: Colors.white,
                                                                      size: 30.0,
                                                                    ),
                                                                    SizedBox(width: 10,),
                                                                    Text('Fecha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),),
                                                                  ],
                                                                  
                                                                ),
                                                                
                                                                Text(
                                                                  asistencia['fecha'] is DateTime
                                                                      ? DateFormat('dd-MM-yyyy').format(asistencia['fecha'])
                                                                      : asistencia['fecha'] ?? 'Fecha no disponible',
                                                                  style: textoDatosProf,
                                                                ),
                                                
                                                              ],
                                                            ),
                                                            const SizedBox(width: 2,),
                                                            Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Icon(Icons.group, color: whiteColor),
                                                                    Text('${asistencia['totalAlumnas'] ?? 'N/A'}', style: textoDatosProf),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  children: [
                                                                    const Icon(Icons.check_circle, color: Colors.green),
                                                                    Text('${asistencia['totalAsistencias'] ?? 'N/A'}', style: textoDatosProf),
                                                                    const SizedBox(width:5,),
                                                                    const Icon(Icons.remove_circle, color: Colors.red,),
                                                                    Text('${asistencia['totalFaltas'] ?? 'N/A'}', style: textoDatosProf),
                                                                    const SizedBox(width:5,),
                                                                    const Icon(Icons.access_time_filled, color: Colors.yellow),
                                                                    Text('${asistencia['totalTardanzas'] ?? 'N/A'}', style: textoDatosProf),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(width: 2,),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: Colors.red, size: 30,),
                                                              onPressed: () => _deleteAsistencia(index),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        
                                                        onPressed: () {
                                                          setState(() {
                                                            _selectedAsistencia = asistencia;
                                                          });
                                                          _exportarPDF();
                                                        },
                                                        child: const Text('Exportar a PDF'),
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.only(left: 15, right: 15),
                                                        ),
                                                        
                                                      ),
                                                      const SizedBox(height: 5,),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                        ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                // LayoutBuilder(
                //   builder: (BuildContext context, BoxConstraints constraints) {
                //     return ElevatedButton(
                //       onPressed: _cerrarSesion,
                //       child: const Text('CERRAR SESION'),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.red, // Cambiar el color a rojo
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(25),
                //         ),
                //         minimumSize: Size(40, 50), // Make it responsive
                //         padding: EdgeInsets.symmetric(horizontal: 16),
                //         textStyle: TextStyle(fontSize: 14),
                //       ),
                //     );
                //   },
                // )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        spacing: 10,
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: fondo1,
        foregroundColor: whiteColor,
        children: [
          
          SpeedDialChild(
            child: Icon(Icons.sort_by_alpha, color: whiteColor),
            backgroundColor: fondo1,
            label: 'Ordenar por Fecha',
            onTap: () {
              setState(() {
                _asistencias.sort((a, b) {
                  // Convertir las fechas a objetos DateTime
                  DateTime? dateA = _parseDate(a['fecha']);
                  DateTime? dateB = _parseDate(b['fecha']);

                  // Manejar casos donde la fecha pueda ser null
                  if (dateA == null && dateB == null) return 0;
                  if (dateA == null) return 1;
                  if (dateB == null) return -1;

                  // Comparar las fechas
                  return dateB.compareTo(dateA); // Orden descendente (más reciente primero)
                });
              });
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.sort, color: whiteColor),
            backgroundColor: fondo1,
            label: 'Ordenar por Grado',
            onTap: () {
              setState(() {
                _asistencias.sort((a, b) => a['seccionId'].compareTo(b['seccionId']));
              });
            },
          ),
        ],
      ),

    ),
  );
}

}
