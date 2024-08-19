import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/widgets/icono.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProfileAux extends StatefulWidget {
  final AppUser profesorId;

  const ProfileAux({Key? key, required this.profesorId}) : super(key: key);

  @override
  _ProfileAuxState createState() => _ProfileAuxState();
}

class _ProfileAuxState extends State<ProfileAux> {
  Map<String, dynamic>? _profesorData;
  String cursoId = '';
  List<Map<String, dynamic>> justificaciones = [];
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _fetchProfesorData();
    _fetchJustificaciones();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _fetchProfesorData() async {
    if (!_mounted) return;

    try {
      // Obtener el documento del profesor
      DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
          .collection('AUXILIARES')
          .doc(widget.profesorId.dni)
          .get();

      if (!_mounted) return; // Verificar nuevamente después de la operación asíncrona

      if (!profesorDoc.exists) {
        print('El documento del profesor no existe.');
        return;
      }

      _profesorData = profesorDoc.data() as Map<String, dynamic>;
      _isLoading = false;

    } catch (e) {
      print('Error fetching data: $e');
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fetchJustificaciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot justificacionesSnapshot = await FirebaseFirestore.instance
          .collection('AUXILIARES')
          .doc(widget.profesorId.dni)
          .collection('JUSTIFICACIONES')
          .get();

      setState(() {
        justificaciones = justificacionesSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'numero_expediente': data['numero_expediente'] ?? '',
            'fecha': data['fecha'] ?? '',
            'estado': data['estado'] ?? '',
            'descripcion_expediente': data['descripcion_expediente'] ?? '',
            'nombreAlumna': data['nombreAlumna'] ?? '',
            'fechaJustificacion': data['fechaJustificacion'],
            'hora': data['hora'],
            'idAlumna': data['idAlumna']
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching justificaciones: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage())); // Asegúrate de tener una ruta de login configurada
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

// Función auxiliar para parsear la fecha y hora y restar 5 horas
DateTime? _parseDateHora(dynamic fecha) {
  if (fecha is DateTime) {
    return fecha.subtract(const Duration(hours: 5));
  }
  if (fecha is Timestamp) {
    return fecha.toDate().subtract(const Duration(hours: 5));
  }
  if (fecha is String) {
    try {
      DateTime parsedDate = DateFormat('dd-MM-yyyy hh:mm:ss a').parse(fecha);
      return parsedDate.subtract(const Duration(hours: 5));
    } catch (e) {
      print('Error parsing date: $fecha');
      return null;
    }
  }
  return null;
}
  void _showJustificacionDialog(Map<String, dynamic> justificacion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? fechaJustificacion = _parseDateHora(justificacion['fechaJustificacion']);
                              String fechaFormatted = fechaJustificacion != null
                                  ? DateFormat('dd-MM-yyyy hh-mm a').format(fechaJustificacion)
                                  : 'Fecha no válida';
        return AlertDialog(
          title: const Text('Justificación'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Expediente: ${justificacion['numero_expediente']}'),
              Text('Alumna: ${justificacion['nombreAlumna']}'),
              Text('Fecha: ${justificacion['fecha']}'),
              Text('Hora: ${justificacion['hora']}'),
              Text('Estado: ${justificacion['estado']}'),
              Text('Descripción: ${justificacion['descripcion_expediente']}'),             
              Text('Fecha Justificación: $fechaFormatted'),
              
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarJustificacion(String justificacionId, String idAlumna, String estadoActual) async {
  try {
    // Obtener el id de la asistencia desde la justificación
    DocumentSnapshot justificacionDoc = await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('JUSTIFICACIONES')
        .doc(justificacionId)
        .get();

    if (!justificacionDoc.exists) {
      print('Justificación no encontrada');
      return;
    }

    String asistenciaId = justificacionDoc['id'];

    // Buscar la asistencia correcta comparando el ID
    DocumentSnapshot asistenciaDoc = await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS')
        .doc(asistenciaId)
        .get();

    if (!asistenciaDoc.exists) {
      print('Asistencia no encontrada');
      return;
    }

    // Verificar si el documento de la alumna existe en DETALLES
    QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS')
        .doc(asistenciaDoc.id)
        .collection('DETALLES')
        .where(FieldPath.documentId, isEqualTo: idAlumna)
        .get();

    if (detallesSnapshot.docs.isEmpty) {
      print('Detalle de la alumna no encontrado');
      return;
    }

    DocumentReference detalleRef = detallesSnapshot.docs.first.reference;

    // Actualizar el estado de la alumna en el documento de detalles correspondiente
    String nuevoEstado;
    if (estadoActual == 'tardanza justificada') {
      nuevoEstado = 'tardanza';
    } else if (estadoActual == 'falta justificada') {
      nuevoEstado = 'falta';
    } else {
      // Si el estado actual no coincide con ninguno de los anteriores,
      // puedes manejarlo como un caso por defecto o lanzar una excepción.
      nuevoEstado = estadoActual; // o lanzar una excepción
    }
    await detalleRef.update({'estado': nuevoEstado});

    // Restar 1 al campo totalJustificaciones de la asistencia
    int totalJustificaciones = asistenciaDoc['totalJustificaciones'] ?? 0;
    await asistenciaDoc.reference.update({
      'totalJustificaciones': totalJustificaciones - 1,
    });

    // Eliminar la justificación
    await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('JUSTIFICACIONES')
        .doc(justificacionId)
        .delete();

    // Refrescar la lista de justificaciones
    _fetchJustificaciones();
  } catch (e) {
    print('Error eliminando justificación: $e');
  }
}

Future<List<Map<String, dynamic>>> getJustificaciones(String profesorId) async {
  List<Map<String, dynamic>> justificaciones = [];
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('AUXILIARES')
      .doc(widget.profesorId.dni)
      .collection('JUSTIFICACIONES')
      .get();

  for (var doc in snapshot.docs) {
    justificaciones.add(doc.data() as Map<String, dynamic>);

  }

  return justificaciones;
}

Future<void> generatePdf(List<Map<String, dynamic>> justificaciones) async {
    final pdf = pw.Document();
    final DateFormat dateFormat = DateFormat('dd-MM-yy HH:mm aa');
    final DateFormat monthFormat = DateFormat('MMMM yyyy');
    final String currentMonth = monthFormat.format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(marginBottom: 10, marginLeft: 10, marginRight: 10, marginTop: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Mes: $currentMonth', style: const pw.TextStyle(fontSize: 18)),
              if (_profesorData != null)
                pw.Text('Profesor: ${_profesorData!['nombre']} ${_profesorData!['apellido_paterno']} ${_profesorData!['apellido_materno']}', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'N° Exp',
                  'Alumna',
                  'DNI',
                  'Estado',
                  'Descripcion Expediente',
                  'Fecha',
                  'Fecha justificado'
                ],
                data: justificaciones.map((justificacion) {
                  return [
                    justificacion['numero_expediente'],
                    justificacion['nombreAlumna'],
                    justificacion['idAlumna'],
                    justificacion['estado'],
                    justificacion['descripcion_expediente'],
                    justificacion['fecha'],
                    dateFormat.format((justificacion['fechaJustificacion'] as Timestamp).toDate())
                  ];
                }).toList(),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 12),
                headerStyle: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(3),
                  5: pw.FlexColumnWidth(2),
                  6: pw.FlexColumnWidth(2),
                },
              ),
            ],
          );
        },
      ),
    );

    // Guardar el PDF en el dispositivo o imprimirlo
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    Color bluegood = const Color.fromARGB(255, 6, 47, 233);
    Color whiteColor = Colors.white70;
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);
    Color fondoDatos = const Color(0XFF001739);
    TextStyle textoDatosProf = TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: whiteText);
    TextStyle textoWhiteLow = TextStyle(color: whiteColor);

    return SafeArea(
      child: Scaffold(
        backgroundColor: fondo2,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(backgroundColor: fondo1, color: bluegood,))
            : Stack(
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
                                const IconoPerfil(),
                                const SizedBox(height: 20),
                                Container(
                                  width: 180,
                                  child: Text(
                                    '${_profesorData?['cursoId'] ?? ''}',
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
                        const SizedBox(height: 13),
                        ElevatedButton(
                          onPressed: () async {
                            List<Map<String, dynamic>> justificaciones = await getJustificaciones(widget.profesorId.dni);
                            await generatePdf(justificaciones);
                          },
                          child: const Text('Exportar a PDF'),
                        ),
                        const SizedBox(height: 13),
                        const Text("JUSTIFICACIONES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 18),),
                        const SizedBox(height: 13,),
                        Expanded(
                          child: ListView.builder(
                            itemCount: justificaciones.length,
                            itemBuilder: (BuildContext context, int index) {
                              Map<String, dynamic> justificacion = justificaciones[index];
                              DateTime? fechaJustificacion = _parseDate(justificacion['fechaJustificacion']);
                              String fechaFormatted = fechaJustificacion != null
                              ? DateFormat('dd-MM-yyyy hh:mm a').format(fechaJustificacion)
                              : 'Fecha no válida';

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: fondo1,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: ListTile(
                                    title: Text('Numero Expediente: ${justificacion['numero_expediente']}', style: textoDatosProf),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 3,),
                                          Text('Nombre: ${justificacion['nombreAlumna']}', style: textoWhiteLow,),
                                          Text('Fecha Justificación: $fechaFormatted', style: textoWhiteLow,),
                                          Text('Estado: ${justificacion['estado']}',style: textoWhiteLow, ),
                                        ],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarJustificacion(justificacion['id'], justificacion['idAlumna'], justificacion['estado']),
                                    ),
                                    onTap: () => _showJustificacionDialog(justificacion),
                                  ),
                                ),
                              );
                            },
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
