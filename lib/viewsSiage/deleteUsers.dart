import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class DeletePageUsuarios extends StatefulWidget {
  @override
  _DeletePageUsuariosState createState() => _DeletePageUsuariosState();
}

class _DeletePageUsuariosState extends State<DeletePageUsuarios> {
  bool _isLoading = false;
  String _message = '';
  List<String> _idsToDelete = [];

  Color whiteColor = const Color(0XFFF6F6F6);
  Color lightBlue = const Color(0XFF0066FF);
  Color fondo1 = const Color(0XFF001220);
  Color whiteText = const Color(0XFFF3F3F3);
  Color fondo2 = const Color(0XFF071E30);

  void _pickFile() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await _readExcel(file);
      } else {
        setState(() {
          _isLoading = false;
          _message = 'No se seleccionó ningún archivo';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error al seleccionar el archivo: $e';
      });
    }
  }

  Future<void> _readExcel(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      var sheet = excel.tables[excel.tables.keys.first];
      setState(() {
        _idsToDelete = sheet!.rows.map((row) {
          var cell = row[0];
          return cell == null || cell.value == null || cell.value.toString().trim().isEmpty ? '' : cell.value.toString().trim();
        }).where((id) => id.isNotEmpty).toList();
        _isLoading = false;
        _message = 'Datos cargados exitosamente desde Excel';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error al leer Excel: $e';
      });
    }
  }

  Future<void> _deleteFromFirestore() async {
    setState(() {
      _isLoading = true;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: 
      Text('Eliminando datos de Firestore y Firebase Auth...')));
    });

    for (var id in _idsToDelete) {
      try {
        var docSnapshot = await FirebaseFirestore.instance.collection('USUARIOS').doc(id).get();
        if (docSnapshot.exists) {
          String? email = docSnapshot.data()?['email'];
          String? contrasena = docSnapshot.data()?['contraseña'];
          if (email != null && contrasena != null) {
            var signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
            if (signInMethods.isNotEmpty) {
              await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: contrasena); 
              User? currentUser = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('USUARIOS').doc(id).delete();
              await currentUser?.delete();
              await FirebaseAuth.instance.signOut();
            }
          }
          
        }
      } catch (e) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al eliminar los datos de Firestore y Firebase Auth $e')));
        });
      }
    }
    
    setState(() {
      _isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Datos eliminados exitosamente de Firestore y Firebase Auth')));
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            }, 
            icon: const Icon(Icons.arrow_back),color: whiteColor, ),
          title: Text('Eliminar usuarios desde archivo', style: TextStyle(
            color: whiteText,
            fontWeight: FontWeight.bold
          ),),
          backgroundColor: fondo2,
        ),
        body: Stack(
          children: [
            Positioned(
              child: Container(
                height: screenHeight,
                width: screenWidth,
                color: fondo2,
              )),
            Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _pickFile,
                        child: const Text('Seleccionar Archivo'),
                      ),
                      const SizedBox(height: 20),
                      Text(_message,style: TextStyle(
                        color: whiteText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600
                      ),),
                      const SizedBox(height: 20),
                      _idsToDelete.isNotEmpty
                          ? Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text('ID',style: TextStyle(
                                      color: whiteText,
                                    ))),
                                  ],
                                  rows: _idsToDelete
                                      .map((id) {
                                        return DataRow(cells: [DataCell(Text(id,style: TextStyle(
                                          color: whiteColor
                                        ),))]);
                                      })
                                      .toList(),
                                ),
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 20),
                      _idsToDelete.isNotEmpty
                          ? ElevatedButton(
                              onPressed: _deleteFromFirestore,
                              child: const Text('Eliminar de Firestore y Firebase Auth'),
                            )
                          : Container(),
                    ],
                  ),
          ),
          ],
        ),
      ),
    );
  }
}
