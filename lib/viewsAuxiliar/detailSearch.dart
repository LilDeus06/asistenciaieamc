import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amc/helpers/timezone_helper.dart';
import 'package:amc/views/loginView.dart';
// ignore: unused_import
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class DetalleAlumnaView extends StatefulWidget {
  final Map<String, dynamic> alumna;
  final AppUser user;
  DetalleAlumnaView({required this.alumna, required this.user});

  @override
  _DetalleAlumnaViewState createState() => _DetalleAlumnaViewState();
    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);
}

class _DetalleAlumnaViewState extends State<DetalleAlumnaView> {
  List<Map<String, dynamic>> _tardanzas = [];
  List<Map<String, dynamic>> _faltas = [];
  List<Map<String, dynamic>> _justificaciones = [];
  bool _isLoading = true;
  String _grado = '';
  String _seccion = '';
  String _celular = "";
  List<Map<String, dynamic>> _dataDetalleAlumna =[];
  String mensajeJustificacion ="";
  String textJustificacion ="";
  String numeroExpe = "";

  @override
  void initState() {
    super.initState();
    _fetchAsistencias();
    _fetchGradoSeccion();
    _fetchCellular();
    tz.initializeTimeZones();
  }

  Future<void> _fetchAsistencias() async {
  try {
    QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('AUXILIARES').get();
    List<Map<String, dynamic>> tardanzas = [];
    List<Map<String, dynamic>> faltas = [];
    List<Map<String, dynamic>> justificaciones = [];

    

    for (var profesorDoc in profesoresSnapshot.docs) {
      String profesorId = profesorDoc.id;
      String cursoId = profesorDoc['cursoId'] ?? '';
      String cursoNombre = 'Curso desconocido';

      print('Procesando profesor: $profesorId');

      if (cursoId.isNotEmpty) {
        DocumentSnapshot cursoDoc = await FirebaseFirestore.instance
            .collection('CURSOS')
            .doc(cursoId)
            .get();
        if (cursoDoc.exists) {
          cursoNombre = cursoDoc['nombre'] ?? 'Curso desconocido';
        }
      }

      print('Curso del profesor: $cursoNombre');

      QuerySnapshot asistenciasSnapshot = await FirebaseFirestore.instance
          .collection('AUXILIARES')
          .doc(profesorId)
          .collection('ASISTENCIAS')
          .get();

      for (var asistenciaDoc in asistenciasSnapshot.docs) {
        String asistenciaId = asistenciaDoc.id;
        String asistenciaFecha = asistenciaDoc['fecha'] ?? '';
        String asistenciaHora = asistenciaDoc['hora'] ?? '';

        print('Procesando asistencia: $asistenciaId');
        print('Fecha de asistencia: $asistenciaFecha');
        print('Hora de asistencia: $asistenciaHora');

        QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
            .collection('AUXILIARES')
            .doc(profesorId)
            .collection('ASISTENCIAS')
            .doc(asistenciaId)
            .collection('DETALLES')
            .get();

        for (var detalleDoc in detallesSnapshot.docs) {
          var data = detalleDoc.data() as Map<String, dynamic>;
          if (data['nombre'] == widget.alumna['nombre'] &&
              data['apellido_paterno'] == widget.alumna['apellido_paterno'] &&
              data['apellido_materno'] == widget.alumna['apellido_materno']) {
            
            data['id'] = detalleDoc.id;
            data['profesorId'] = profesorId;
            data['asistenciaId'] = asistenciaId;
            data['cursoNombre'] = cursoNombre;
            data['fecha'] = asistenciaFecha;

            // Usar la fecha y hora de la asistencia
            if (asistenciaFecha.isNotEmpty && asistenciaHora.isNotEmpty) {
              data['hora'] = asistenciaFecha;
              
              
              
               // Parsear la fecha y hora correctamente
              // try {
              //   // Asumiendo que la fecha está en formato dd-MM-yyyy
              //   List<String> fechaParts = asistenciaFecha.split('-');
              //   if (fechaParts.length == 3) {
              //     String fechaFormatted = '${fechaParts[2]}-${fechaParts[1]}-${fechaParts[0]}'; // Convertir a yyyy-MM-dd
              //     DateTime fechaHora = DateTime.parse('$fechaFormatted $asistenciaHora');
                  
              //     // Ajustar a hora de Lima (UTC-5)
              //     fechaHora = fechaHora.subtract(Duration(hours: 0));
              //     data['fechaHora'] = DateFormat('dd-MM-yyyy HH:mm a').format(fechaHora);
              //   } else {
              //     data['fechaHora'] = 'Formato de fecha inválido';
              //   }
              // } catch (e) {
              //   print('Error al parsear fecha y hora: $e');
              //   data['fechaHora'] = 'Error en fecha/hora';
              // }
            } else {
              data['fechaHora'] = 'Fecha/hora no disponible';
            }

            print('Detalle encontrado para alumna:');
            print('Nombre: ${data['nombre']} ${data['apellido_paterno']} ${data['apellido_materno']}');
            print('Estado: ${data['estado']}');
            print('Fecha y hora: ${data['fecha']}');

            if (data['estado'] == 'tardanza') {
              tardanzas.add(data);
            } else if (data['estado'] == 'falta') {
              faltas.add(data);
            } else if (data['estado'] == 'tardanza justificada' || data['estado'] == 'falta justificada' || data['estado'] == 'falta justificada') {
              justificaciones.add(data);
            }
          }
        }
      }
    }

    setState(() {
      _tardanzas = tardanzas;
      _faltas = faltas;
      _justificaciones = justificaciones;
      _isLoading = false;
    });

    print('Tardanzas encontradas: ${_tardanzas.length}');
    print('Faltas encontradas: ${_faltas.length}');
    print('Justificaciones encontradas: ${_justificaciones.length}');

  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Error fetching asistencias: $e');
  }
}

  Future<void> _fetchGradoSeccion() async {
  try {
    DocumentSnapshot alumnaDoc = await FirebaseFirestore.instance
        .collection('ALUMNAS')
        .doc(widget.alumna['id'])
        .get();

    if (alumnaDoc.exists) {
      var data = alumnaDoc.data() as Map<String, dynamic>;
      String seccionId = data['seccionId'] ?? '';
      if (seccionId.isNotEmpty && seccionId.length == 3) {
        // Separar grado y sección
        _grado = seccionId.substring(1, 2); // Extraer solo el número del grado
        _seccion = seccionId.substring(2); // Extraer la última letra como sección
        setState(() {});
      }
    }
  } catch (e) {
    print('Error fetching grado y seccion: $e');
  }
}



  Future<void> _justificarAsistencia(String alumnoId, String profesorId, String asistenciaId) async {
    try {
      DocumentReference estadoRef = FirebaseFirestore.instance.collection('AUXILIARES')
        .doc(profesorId)
        .collection('ASISTENCIAS')
        .doc(asistenciaId)
        .collection('DETALLES')
        .doc(alumnoId);

      // Referencia al documento de asistencia
      DocumentReference asistenciaRef = FirebaseFirestore.instance.collection('AUXILIARES')
      .doc(profesorId)
      .collection('ASISTENCIAS')
      .doc(asistenciaId);


      DocumentSnapshot _dataDetalleAlumna = await estadoRef.get();
      final String justificacion = '${_dataDetalleAlumna['estado']} justificada';

      await estadoRef
          .update({
        'estado': justificacion,
      });

      // Incrementar el contador de justificaciones en el documento de asistencia
      await asistenciaRef.update({
        'totalJustificaciones': FieldValue.increment(1),
      });

  
      // Obtener los datos necesarios para la justificación
    String idAsistencia = asistenciaId.toString();
    String idAlumna = alumnoId.toString();
    String fecha = _dataDetalleAlumna['fecha'] ?? '';
    String hora = _dataDetalleAlumna['hora'] ?? '';
    // String grado2 = _dataDetalleAlumna['seccionId'];
    String nombreAlumna = '${widget.alumna['nombre']} ${widget.alumna['apellido_paterno']} ${widget.alumna['apellido_materno']}';

    // Guardar la justificación
    await guardarJustificacion(fecha, hora, justificacion, nombreAlumna, idAlumna, idAsistencia);

      print('Asistencia justificada con éxito para el alumno con ID: $alumnoId');
      _fetchAsistencias();
    } catch (e) {
      print('Error justificando asistencia: $e');
    }
  }

  Future<void> guardarJustificacion(String fecha, String hora, String justificacion, String nombreAlumna, String idAlumna, String idAsistencia) async {
  try {

    // Obtén la fecha y hora actual en el horario de Lima
    DateTime fechaJustificacion = tz.TZDateTime.now(tz.local);
    // Referencia a la colección principal
    CollectionReference auxiliaresRef = FirebaseFirestore.instance.collection('AUXILIARES');
    
    // Documento del usuario actual
    DocumentReference userDocRef = auxiliaresRef.doc(widget.user.dni);

    // Referencia a la subcolección "JUSTIFICACIONES"
    CollectionReference justificacionesRef = userDocRef.collection('JUSTIFICACIONES');

    // Crear un nuevo documento con ID automático
    await justificacionesRef.add({
      'numero_expediente': numeroExpe,
      'descripcion_expediente':textJustificacion,
      'fecha': fecha,
      'hora': hora,
      'estado': justificacion,
      'nombreAlumna': nombreAlumna,
      'fechaJustificacion': fechaJustificacion,
      'idAlumna': idAlumna,
      'id': idAsistencia,
      // 'seccionId': grado2, // Añade la fecha y hora actual del servidor
    });

    print('Justificación guardada exitosamente');
  } catch (e) {
    print('Error al guardar la justificación: $e');
  }
}


  Future<void> _cambiarEstadoAsistencia(String profesorId, String asistenciaId, String detalleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('AUXILIARES')
          .doc(profesorId)
          .collection('ASISTENCIAS')
          .doc(asistenciaId)
          .collection('DETALLES')
          .doc(detalleId)
          .update({
        'estado': 'asistencia',
      });

      _fetchAsistencias();
    } catch (e) {
      print('Error changing asistencia state: $e');
    }
  }

  Future<void> _eliminarTodasAsistencias() async {
    try {
      QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('AUXILIARES').get();

      for (var profesorDoc in profesoresSnapshot.docs) {
        String profesorId = profesorDoc.id;
        QuerySnapshot asistenciasSnapshot = await FirebaseFirestore.instance
            .collection('AUXILIARES')
            .doc(profesorId)
            .collection('ASISTENCIAS')
            .get();

        for (var asistenciaDoc in asistenciasSnapshot.docs) {
          String asistenciaId = asistenciaDoc.id;
          
          QuerySnapshot detallesSnapshot = await FirebaseFirestore.instance
              .collection('AUXILIARES')
              .doc(profesorId)
              .collection('ASISTENCIAS')
              .doc(asistenciaId)
              .collection('DETALLES')
              .get();

          for (var detalleDoc in detallesSnapshot.docs) {
            var data = detalleDoc.data() as Map<String, dynamic>;
            if (data['nombre'] == widget.alumna['nombre'] &&
                data['apellido_paterno'] == widget.alumna['apellido_paterno'] &&
                data['apellido_materno'] == widget.alumna['apellido_materno']) {
              await detalleDoc.reference.update({
                'estado': 'asistencia',
              });
            }
          }
        }
      }

      setState(() {
        _tardanzas.clear();
        _faltas.clear();
        _justificaciones.clear();
      });

      print('Todas las asistencias de la alumna han sido eliminadas');
    } catch (e) {
      print('Error eliminando todas las asistencias: $e');
    }
  }
  Future<String> _searchCelular(String alumnaId) async {
    
    try {
      DocumentSnapshot docSnapshot =
          await FirebaseFirestore.instance.collection('ALUMNAS').doc(alumnaId).get();
      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        String celular =data["celular_apoderado"];
        return celular;
      } else {
        return 'No registrado';
      }
    } catch (e) {
      return 'No registrado';
    }
  }
  Future<void> _fetchCellular() async {
    String celular = await _searchCelular(widget.alumna['id']);
    setState(() {
      _celular = celular;
      print('Celular encontrado: $_celular');
    });
  }

  Future<void> _makeCall() async {
    if (_celular.isNotEmpty && _celular != 'No registrado') {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: '+51$_celular',
      );
      if(await canLaunchUrl(launchUri)){
        await launchUrl(launchUri);
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se puede realizar la llamada")),
      );
    }
    }
  }

  Future<void> _openWhatsAppDirect() async {
  if (_celular.isNotEmpty && _celular != 'No registrado') {
    // Asegúrate de que el número de teléfono esté en el formato correcto
    String phoneNumber = _celular.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Intenta abrir WhatsApp directamente
    final Uri whatsappUri = Uri.parse('whatsapp://send?phone=51$phoneNumber');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Si no se puede abrir directamente, intenta con el enlace web
      final Uri webWhatsappUri = Uri.parse('https://wa.me/51$phoneNumber');
      if (await canLaunchUrl(webWhatsappUri)) {
        await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp")),
        );
      }
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Número de teléfono no válido")),
    );
  }
}

Future<void> _showInputDialog(String alumnoId, String profesorId, String asistenciaId) async {
    TextEditingController textController = TextEditingController();
    TextEditingController numeroExpediente = TextEditingController();
    

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          backgroundColor: const Color(0XFF001220),
          elevation: 20.0,
          title: const Text('Ingrese los datos de la justificación',
          style: TextStyle(color: Colors.white70, fontSize: 17,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                        style: const TextStyle(color: Colors.white70),
                        controller: numeroExpediente,
                          decoration: const InputDecoration(labelText: 'Número de expediente', 
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.numbers_sharp),
                          ),
                        maxLength: 8,
                        canRequestFocus: true,
                        keyboardType: TextInputType.number,
                        
                      ),
              TextField(
                style: const TextStyle(color: Colors.white70),
                        controller: textController,
                        scribbleEnabled: true,
                        canRequestFocus: true,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 75,
                          decoration: const InputDecoration(labelText: 'Motivo de la justificacion', 
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.draw_rounded),  
                          ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: (){Navigator.of(context).pop();}, 
            child: Text("Cancelar"),
            style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF001220), // Background color
                    disabledBackgroundColor: Colors.white, // Text color
                    shadowColor: Colors.black, // Shadow color
                    elevation: 5, // Elevation (shadow depth)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    )
              ),
            ),
            ElevatedButton(onPressed: (){
              if (numeroExpediente.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No puede estar vacio el codigo'),
                    ),
                  );
                } else {               
                textJustificacion = textController.text;
                numeroExpe = numeroExpediente.text; // Guarda el texto ingresado
                _justificarAsistencia(alumnoId, profesorId, asistenciaId);
                  Navigator.of(context).pop();
                }
                setState(() {
                  mensajeJustificacion = textJustificacion;
                });
                print('Numero de justificacion: $numeroExpe \nMensaje de justificación: $mensajeJustificacion');
            }, 
            child: const Text("Aceptar", style: TextStyle(color: Colors.white70),),
            style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(213, 55, 32, 160), // Background color // Text color
                    shadowColor: Colors.black, // Shadow color
                    elevation: 5, // Elevation (shadow depth)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    )
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMessageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Datos de la justificación'),
          content: Text(mensajeJustificacion), //el mensaje solo se muestra si se justifica y se selecciona para mostrar
          //dentro de la misma ventana si se sale de la ventana no aparece mensaje ya que no esta en firebase.
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      backgroundColor: const Color(0XFF071E30),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                      Container(
                        alignment: const Alignment(0, 0),
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0XFF001220),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              spreadRadius: 3,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          "DETALLES DE ASISTENCIA",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 15),
    
                      //AQUI VA EL CONTAINER
                      Container(
                        height: 200,
                        width: 500,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0XFF001220),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.16),
                                      spreadRadius: 3,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          width: 400,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD3E5FF),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.16),
                                                spreadRadius: 3,
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: Text(
                                              '${widget.alumna['nombre'].toString().trim()} ',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10, top: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          width: 400,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD3E5FF),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.16),
                                                spreadRadius: 3,
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: Text(
                                              '${widget.alumna['apellido_paterno'].toString().trim()} ',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            width: 400,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD3E5FF),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.16),
                                                  spreadRadius: 3,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 10),
                                              child: Text(
                                                '${widget.alumna['apellido_materno'].toString().trim()} ',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0XFF001220),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.16),
                                        spreadRadius: 3,
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  width: 200,
                                  height: 200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      
                                      const Icon(
                                        Icons.person_3,
                                        color: Colors.blue,
                                        size: 150,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text("GRADO: $_grado", style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,),),
                                        const SizedBox(width: 10,),
                                        Text("SECCION: $_seccion", style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,),),
                                      ],
                                      ),
                                    ],
                                  ),
                                  
                                ),
                                
                              ],
                            ),
                          ],
                        ),
                      ),
                      if(_celular.isNotEmpty && _celular != "No registrado")
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                      children: [ 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(iconSize: 32,
                              icon: const Icon(Icons.delete_forever),
                              onPressed: _eliminarTodasAsistencias,
                              color: Colors.red,
                            ),
                            Text("Eliminar Todo", style: TextStyle(color: Colors.white),),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(iconSize: 30,
                              icon: const Icon(Icons.call),
                              onPressed: _makeCall,
                              color: Colors.green,
                            ),
                            Text("Llamar Apoderado", style: TextStyle(color: Colors.white),),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(iconSize: 30,
                              icon: const Icon(Icons.chat_bubble_rounded),
                              onPressed: _openWhatsAppDirect,
                              color: Colors.green,
                            ),
                            Text("WhatsApp", style: TextStyle(color: Colors.white),),
                          ],
                        ),
                      ],
                    ),),
                          )
                      else 
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12,),
                            IconButton(iconSize: 32,
                              icon: const Icon(Icons.delete_forever),
                              onPressed: _eliminarTodasAsistencias,
                              color: Colors.red,
                            ),
                            const Text("Eliminar Todo", style: TextStyle(color: Colors.white),),
                            const SizedBox(height: 15,),
                          ],
                        ),
                      ),
                      const Text('ESTADISTICAS TOTALES',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    // Text(
                    //   '${widget.alumna['nombre']} ${widget.alumna['apellido_paterno']} ${widget.alumna['apellido_materno']}',
                    //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    // ),
                    // SizedBox(height: 8),
                    // Text('Grado: $_grado'),
                    // Text('Sección: $_seccion'),
                    // SizedBox(height: 16),
                    
                    const SizedBox(height: 10),
                    _buildAsistenciasList('Tardanzas', _tardanzas),
                    _buildAsistenciasList('Faltas', _faltas),
                    _buildAsistenciasList('Justificaciones', _justificaciones),
                  ],
                ),
              ),
            ),
    ),
  );
}

Widget _buildAsistenciasList(String title, List<Map<String, dynamic>> asistencias) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      const SizedBox(height: 8),
      asistencias.isEmpty
          ? Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text('No hay $title registradas',style: const TextStyle(
                              fontSize: 17,                              
                              color: Colors.white)),
          )
          : Column(
              children: asistencias.map((asistencia) {
                return Card(
                  color: const Color(0XFF001220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),  
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha : ${asistencia['fecha']}', style: TextStyle(color: Colors.white),),
                          if (title == 'Justificaciones' && asistencia['fechaHoraJustificacion'] != null)
                            Text('Justificado el: ${asistencia['fechaHoraJustificacion']}'),
                        ],
                      ),

                      Row(
                        children: [
                          if (title != 'Justificaciones')
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.greenAccent,),
                            onPressed: () => _showInputDialog(
                              asistencia['id'],
                              asistencia['profesorId'],
                              asistencia['asistenciaId'],
                            ),
                          ),
                        if (title == 'Justificaciones')
                          IconButton(
                            onPressed: _openMessageDialog, 
                            icon: Icon(Icons.description,color: Colors.greenAccent)),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _cambiarEstadoAsistencia(
                            asistencia['profesorId'],
                            asistencia['asistenciaId'],
                            asistencia['id'],
                          ),
                        ),
                        ],
                      ),
                    ],
                  ),
                  // child: ListTile(
                  //   title: Column(
                  //     children: [
                        
                  //     ],
                  //   ),
                  //   subtitle: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text('Fecha : ${asistencia['fecha']}', style: TextStyle(color: Colors.white),),
                  //       if (title == 'Justificaciones' && asistencia['fechaHoraJustificacion'] != null)
                  //         Text('Justificado el: ${asistencia['fechaHoraJustificacion']}'),
                  //     ],
                  //   ),
                  //   trailing: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       if (title != 'Justificaciones')
                  //         IconButton(
                  //           icon: Icon(Icons.check, color: Colors.greenAccent,),
                  //           onPressed: () => _showInputDialog(
                  //             asistencia['id'],
                  //             asistencia['profesorId'],
                  //             asistencia['asistenciaId'],
                  //           ),
                  //         ),
                  //       if (title == 'Justificaciones')
                  //         IconButton(
                  //           onPressed: _openMessageDialog, 
                  //           icon: Icon(Icons.description,color: Colors.greenAccent)),
                  //       IconButton(
                  //         icon: Icon(Icons.delete, color: Colors.red),
                  //         onPressed: () => _cambiarEstadoAsistencia(
                  //           asistencia['profesorId'],
                  //           asistencia['asistenciaId'],
                  //           asistencia['id'],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                );
              }).toList(),
            ),
      const SizedBox(height: 16),
    ],
  );
}
}