import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:amc/views/detailAssistance.dart';
import 'package:amc/views/loginView.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AsistenciasPorMesView extends StatefulWidget {
  final AppUser profesorId;

  const AsistenciasPorMesView({Key? key, required this.profesorId}) : super(key: key);

  @override
  _AsistenciasPorMesViewState createState() => _AsistenciasPorMesViewState();
}

class _AsistenciasPorMesViewState extends State<AsistenciasPorMesView> {
  List<Map<String, dynamic>> _asistencias = [];
  bool _isLoading = false;
  Map<String, Map<String, List<Map<String, dynamic>>>> _asistenciasPorMesYSeccion = {};

  @override
  void initState() {
    super.initState();
    _loadAsistencias();
  }

  Future<void> _loadAsistencias() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    List<String>? asistenciasString = prefs.getStringList('asistencias');

    if (asistenciasString != null) {
      _asistencias = asistenciasString.map((asistencia) {
        Map<String, dynamic> asistenciaMap = jsonDecode(asistencia) as Map<String, dynamic>;
        if (asistenciaMap['fecha'] is String) {
          asistenciaMap['fecha'] = asistenciaMap['fecha'];
        }
        return asistenciaMap;
      }).toList();

      _agruparAsistenciasPorMesYSeccion();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _agruparAsistenciasPorMesYSeccion() {
    _asistenciasPorMesYSeccion.clear();
    for (var asistencia in _asistencias) {
      String fechaStr = asistencia['fecha'];
      DateTime fecha = DateFormat('dd-MM-yyyy').parse(fechaStr);
      String mesKey = DateFormat('MMMM yyyy').format(fecha);
      String seccionId = asistencia['seccionId'];

      if (!_asistenciasPorMesYSeccion.containsKey(mesKey)) {
        _asistenciasPorMesYSeccion[mesKey] = {};
      }
      if (!_asistenciasPorMesYSeccion[mesKey]!.containsKey(seccionId)) {
        _asistenciasPorMesYSeccion[mesKey]![seccionId] = [];
      }
      _asistenciasPorMesYSeccion[mesKey]![seccionId]!.add(asistencia);
    }
  }

  Future<void> _fetchAsistenciasFromFirebase() async {
    setState(() {
      _isLoading = true;
    });

    CollectionReference asistenciasRef = FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS');

    QuerySnapshot querySnapshot = await asistenciasRef.get();
    _asistencias = querySnapshot.docs.map((doc) {
      Map<String, dynamic> asistencia = doc.data() as Map<String, dynamic>;
      asistencia['id'] = doc.id;
      if (asistencia['fecha'] is Timestamp) {
        asistencia['fecha'] = DateFormat('dd-MM-yyyy').format((asistencia['fecha'] as Timestamp).toDate());
      }
      return asistencia;
    }).toList();

    _agruparAsistenciasPorMesYSeccion();

    // Guardar asistencias en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> asistenciasString = _asistencias.map((a) => jsonEncode(a)).toList();
    await prefs.setStringList('asistencias', asistenciasString);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _eliminarAsistencia(String id) async {
  try {
    // Referencia a la colección de asistencias
    CollectionReference asistenciasRef = FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.profesorId.dni)
        .collection('ASISTENCIAS');

    // Referencia al documento de asistencia específico
    DocumentReference asistenciaDocRef = asistenciasRef.doc(id);

    // Obtener y eliminar todos los detalles de la asistencia
    QuerySnapshot detallesSnapshot = await asistenciaDocRef.collection('DETALLES').get();
    for (var doc in detallesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Eliminar el documento de asistencia
    await asistenciaDocRef.delete();

    setState(() {
      _asistencias.removeWhere((asistencia) => asistencia['id'] == id);
      _agruparAsistenciasPorMesYSeccion();
    });

    // Actualizar SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> asistenciasString = _asistencias.map((a) => jsonEncode(a)).toList();
    await prefs.setStringList('asistencias', asistenciasString);

  } catch (e) {
    // Manejar error de eliminación
    print('Error al eliminar la asistencia: $e');
  }
}


@override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0XFF071E30),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.only(top: 14, left:10, right: 10, bottom: 10),
                child: Column(
                  children: [
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
                      child: const Center(child: Text("ASISTENCIAS GUARDADAS", 
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                          ),
                        )),
                    ),
                    
                    Expanded(
                      child: ListView.builder(
                        itemCount: _asistenciasPorMesYSeccion.length,
                        itemBuilder: (context, index) {
                          String mes = _asistenciasPorMesYSeccion.keys.elementAt(index);
                          Map<String, List<Map<String, dynamic>>> seccionesDelMes = _asistenciasPorMesYSeccion[mes]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(mes, style: const TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70
                                    )
                                  ),
                                ),
                              ),
                              ...seccionesDelMes.entries.map((entry) {
                                String seccionId = entry.key;
                                List<Map<String, dynamic>> asistenciasDeSeccion = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                          child: Text('Sección: $seccionId', style: const TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70
                                          )),
                                        ),
                                      ],
                                    ),
                                    ...asistenciasDeSeccion.map((asistencia) {
                                      return GestureDetector(
                                        onTap: ( ){
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => detailAssistancePage(seccionId: seccionId, profesorId:widget.profesorId , asistenciaId: asistencia['id'],)));
                                        },
                                        child: Card(
                                          color: const Color(0XFF001220),
                                          child: Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                
                                                Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text('Fecha: ${asistencia['fecha']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                                        const SizedBox(width: 18),
                                                        Text('Sección: ${asistencia['seccionId']}', style: const TextStyle(color: Colors.white70)),
                                                      ],
                                                    ),
                                                    
                                                    const SizedBox(height: 5,),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.group, color: Colors.blue),
                                                        const SizedBox(width: 4),
                                                        Text('Total: ${asistencia['totalAlumnas'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5,),
                                        
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.check_circle, color: Colors.green),
                                                        const SizedBox(width: 4),
                                                        Text('${asistencia['totalAsistencias'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                                                        const SizedBox(width: 8),
                                                        Icon(Icons.remove_circle, color: Colors.red),
                                                        const SizedBox(width: 4),
                                                        Text('${asistencia['totalFaltas'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                                                        const SizedBox(width: 8),
                                                        const Icon(Icons.access_time, color: Colors.orange),
                                                        const SizedBox(width: 4),
                                                        Text('${asistencia['totalTardanzas'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                                                        const SizedBox(width: 8),
                                                        const Icon(Icons.fact_check, color: Colors.white),
                                                        const SizedBox(width: 4),
                                                        Text('${asistencia['totalJustificaciones'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 5,),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _eliminarAsistencia(asistencia['id']),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.amber,
          mini:true,
          onPressed: _fetchAsistenciasFromFirebase,
          child: Icon(Icons.refresh,),
          tooltip: 'Cargar Asistencias',
          ),
        ),
      );
  }
}
