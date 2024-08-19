import 'package:firebase_auth/firebase_auth.dart';
import 'package:amc/viewsAuxiliar/detailSearch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:amc/views/loginView.dart';

Color whiteColor = const Color(0XFFF6F6F6);
Color lightBlue = const Color(0XFF0066FF);
Color fondo1 = const Color(0XFF001220);
Color whiteText = const Color(0XFFF3F3F3);
Color fondo2 = const Color(0XFF071E30);
String buscar = "Buscar";

class BuscarView extends StatefulWidget {
  final AppUser user; 

  BuscarView({required this.user,});

  @override
  _BuscarViewState createState() => _BuscarViewState();
}

class _BuscarViewState extends State<BuscarView> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _alumnas = [];
  List<Map<String, dynamic>> _filteredAlumnas = [];
  bool _isLoading = true;
  List<dynamic> _seccionData = [];
  String cursoId = '';
  String _currentDate = '';
  Map<String, dynamic>? _profesorData;
  // ignore: unused_field
  bool _isSortedByName = true;

  @override
  void initState() {
    super.initState();
    _fetchProfesorData2();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedAlumnas = prefs.getString('alumnas');
    if (savedAlumnas != null) {
      List<Map<String, dynamic>> alumnas = List<Map<String, dynamic>>.from(json.decode(savedAlumnas));
      setState(() {
        _alumnas = alumnas;
        _filteredAlumnas = alumnas;
        _isLoading = false;
      });
    } else {
      _fetchData();
    }
  }

  void _fetchProfesorData2() async {
  try {
    // Obtener el documento del profesor
    DocumentSnapshot profesorDoc = await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.user.dni)
        .get();

    if (!profesorDoc.exists) {
      profesorDoc = await FirebaseFirestore.instance
        .collection('OWNERS')
        .doc(widget.user.dni)
        .get();

        if (!profesorDoc.exists) {
        print('El documento del profesor no existe en ninguna colección.');
        return;
      }
    }


    print('Profesor Data: ${profesorDoc.data()}');

    // Actualizar el estado con los datos del profesor
    setState(() {
      _profesorData = profesorDoc.data() as Map<String, dynamic>;
      cursoId = profesorDoc['cursoId'];
    });


   // Obtener las secciones desde la subcolección SECCIONES
    QuerySnapshot seccionesSnapshot = await profesorDoc.reference.collection('SECCIONES').get();


    if (seccionesSnapshot.docs.isEmpty) {
      print('No se encontraron secciones.');
    } else {
      // Convertir los documentos de la subcolección en una lista de mapas
      List<Map<String, dynamic>> seccionesData = seccionesSnapshot.docs.map((doc) {
        //print('Sección ID: ${doc.id}');       //AQUI IMPRIME LAS SECCIONES QUE SON ID
        //print('Sección Data: ${doc.data()}');   //AQUI IMPRIME DENTRO DE LAS SECCIONES QUE CAMPOS TIENE
        //print('Sección ID: ${doc.id}');       //AQUI IMPRIME LAS SECCIONES QUE SON ID
        //print('Sección Data: ${doc.data()}');   //AQUI IMPRIME DENTRO DE LAS SECCIONES QUE CAMPOS TIENE
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();

      // Actualizar el estado con los datos de las secciones
      setState(() {
        _seccionData = seccionesData;
      });

      print('Secciones Data: $_seccionData'); //AQUI IMPRIME LO QUE SON DENTRO DE LOS CAMPOS QUE HAY DENTRO
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot profesoresSnapshot = await FirebaseFirestore.instance.collection('AUXILIARES').get();
      
       // Si no existen documentos en AUXILIARES, buscar en OWNERS
    if (profesoresSnapshot.docs.isEmpty) {
      profesoresSnapshot = await FirebaseFirestore.instance.collection('OWNERS').get();

      if (profesoresSnapshot.docs.isEmpty) {
        print('No se encontraron profesores en ninguna colección.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }
      
      
      Map<String, Map<String, dynamic>> alumnasMap = {};

      // Obtener los IDs de las secciones
      List<String> seccionIds = _seccionData.map((seccion) => seccion['id'] as String).toList();

      for (var profesorDoc in profesoresSnapshot.docs) {
        QuerySnapshot asistenciasSnapshot = await profesorDoc.reference.collection('ASISTENCIAS').get();

        for (var asistenciaDoc in asistenciasSnapshot.docs) {
          var asistenciaData = asistenciaDoc.data() as Map<String, dynamic>;

        // Filtrar por seccionId
        if (!seccionIds.contains(asistenciaData['seccionId'])) {
          continue;
        }

          String formattedDate;

          if (asistenciaData.containsKey('fecha')) {
            var fecha = asistenciaData['fecha'];
            if (fecha is Timestamp) {
              DateTime date = fecha.toDate();
              formattedDate = "${date.day}/${date.month}/${date.year}";
            } else if (fecha is String) {
              formattedDate = fecha;
            } else {
              formattedDate = "Fecha desconocida";
            }
          } else {
            formattedDate = "Fecha desconocida";
          }

          QuerySnapshot detallesSnapshot = await asistenciaDoc.reference.collection('DETALLES')
              .where('estado', whereIn: ['falta', 'tardanza', 'falta justificada', 'tardanza justificada'])
              .get(); 

          for (var detalleDoc in detallesSnapshot.docs) {
            var detalleData = detalleDoc.data() as Map<String, dynamic>;

            alumnasMap[detalleDoc.id] = {
              'id': detalleDoc.id,
              'nombre': detalleData['nombre'],
              'apellido_paterno': detalleData['apellido_paterno'],
              'apellido_materno': detalleData['apellido_materno'],
              'fecha': formattedDate,
              'estado': detalleData['estado'],
              'seccionId': detalleData['seccionId'],
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          _alumnas = alumnasMap.values.toList();
          _filteredAlumnas = _alumnas;
          _isLoading = false;
        });
        _saveData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching data: $e'),
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Busqueda actualizada exitosamente'),
    ));
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('alumnas', json.encode(_alumnas));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortByName() {
    setState(() {
      _filteredAlumnas.sort((a, b) => a['nombre'].compareTo(b['nombre']));
      _isSortedByName = true;
    });
  }

  void _sortByDate() {
  setState(() {
    _filteredAlumnas.sort((a, b) {
      DateTime? dateA = _parseDate(a['fecha']);
      DateTime? dateB = _parseDate(b['fecha']);
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });
    _isSortedByName = false;
  });
}

DateTime? _parseDate(String dateStr) {
  List<String> formats = ['dd-MM-yyyy', 'd/M/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'];
  for (String format in formats) {
    try {
      return DateFormat(format).parse(dateStr);
    } catch (_) {
      // Si falla, intenta con el siguiente formato
    }
  }
  print('No se pudo parsear la fecha: $dateStr');
  return null;
}

  void _debouncedSearch(String query) {
    setState(() {
      _filteredAlumnas = _alumnas.where((alumna) {
        return alumna['nombre'].toLowerCase().contains(query.toLowerCase()) ||
            alumna['apellido_paterno'].toLowerCase().contains(query.toLowerCase()) ||
            alumna['apellido_materno'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF071E30),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                alignment: const Alignment(0, 0),
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF001220),
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
                  "BUSQUEDA DE ALUMNAS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF071E30),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: Container(
                  color: const Color(0xFF071E30),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A5386),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize:19),
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintStyle: TextStyle(color: Colors.white24),
                              hintText: "Buscar",
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Colors.white38,),
                            ),
                            onChanged: _debouncedSearch,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _filteredAlumnas.isEmpty
                              ? const Center(child: Text('No hay datos', style: TextStyle(fontSize: 20, color: Colors.white60),))
                              : ListView.builder(
                            itemCount: _filteredAlumnas.length,
                            itemBuilder: (context, index) {
                              final alumna = _filteredAlumnas[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetalleAlumnaView(
                                        alumna: alumna,
                                        user: widget.user,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF001220),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top:8.0),
                                    child: ListTile(
                                      leading: const Icon(Icons.person, size: 50, color: Colors.white),
                                      title: Text(
                                        '${alumna['nombre'].toString().trimLeft()} ${alumna['apellido_paterno'].toString().trimLeft()} ${alumna['apellido_materno'].toString().trimLeft()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Fecha: ${alumna['fecha']}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (alumna['estado'] == 'falta')
                                            const Icon(Icons.remove_circle, color: Colors.red, size: 30),
                                          if (alumna['estado'] == 'tardanza')
                                            const Icon(Icons.access_time_filled, color: Colors.yellow, size: 30),
                                          if (alumna['estado'] == 'falta justificada' || alumna['estado'] == 'tardanza justificada')
                                            const Icon(Icons.playlist_add_check_circle_rounded, color: Color.fromARGB(255, 221, 221, 221), size: 30),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        spacing: 10,
        backgroundColor: const Color(0XFF001220),
        foregroundColor: whiteColor,
        animatedIcon: AnimatedIcons.menu_close,      
        children: [
          SpeedDialChild(
            child: Icon(Icons.sort_by_alpha, color: whiteColor),
            backgroundColor: fondo1,
            label: 'Ordenar por Nombre',
            onTap: _sortByName,
          ),
          SpeedDialChild(
            child: Icon(Icons.date_range, color: whiteColor),
            backgroundColor: fondo1,
            label: 'Ordenar por Fecha',
            onTap: _sortByDate,
          ),
          SpeedDialChild(
            child: Icon(Icons.refresh, color: whiteColor),
            backgroundColor: fondo1,
            label: 'Actualizar',
            onTap: _fetchData,
          ),
        ],
      ),
    );
  }
}
