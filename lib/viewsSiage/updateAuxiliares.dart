import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amc/views/mainView.dart';

class UploadPageAuxiliares extends StatefulWidget {
  @override
  _UploadPageAuxiliaresState createState() => _UploadPageAuxiliaresState();
}

class _UploadPageAuxiliaresState extends State<UploadPageAuxiliares> {
  bool _isLoading = false;
  String _message = '';
  List<List<dynamic>> _data = [];

  void _pickFile() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        if (result.files.single.extension == 'csv') {
          await _readCSV(file);
        } else if (result.files.single.extension == 'xlsx') {
          await _readExcel(file);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = 'No se seleccionó ningún archivo';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Error al seleccionar el archivo: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _readCSV(File file) async {
    try {
      final input = file.openRead();
      final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();

      if (mounted) {
        setState(() {
          _data = fields.skip(1).map((row) {
            // Saltar la primera fila de encabezado
            return row.map((cell) => cell == null || cell.toString().trim().isEmpty ? '' : cell).toList();
          }).toList();
          _message = 'Datos cargados exitosamente desde CSV';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error al leer CSV: $e';
        });
      }
    }
  }

  Future<void> _readExcel(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      var sheet = excel.tables[excel.tables.keys.first];
      if (mounted) {
        setState(() {
          _data = sheet!.rows.map((row) {
            // Saltar la primera fila de encabezado
            return row.map((cell) => cell == null || cell.value == null || cell.value.toString().trim().isEmpty ? '' : cell.value).toList();
          }).toList();
          _message = 'Datos cargados exitosamente desde Excel';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error al leer Excel: $e';
        });
      }
    }
  }

  Future<void> _uploadDataToFirestore() async {
    if (!mounted) return; // Verifica si el widget sigue montado antes de realizar la operación
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: 
      Text('Subiendo datos a Firestore...')));

    try {
      bool hasEmptyCells = false;
      for (var i = 1; i < _data.length; i++) {
        var row = _data[i];
        String auxiliarId = row[0]?.toString() ?? '';
        if (auxiliarId.isEmpty) {
          hasEmptyCells = true;
          break;
        }
        try {
          String apellidoPaterno = row[2]?.toString().trim() ?? '';
          String apellidoMaterno = row[3]?.toString().trim() ?? '';
          String nombre = row[1]?.toString().trim() ?? '';
          String genero = row[4]?.toString().trim() ?? '';
          String curso = row[5]?.toString().trim() ?? '';

          // Lineas para poder convertir automaticamente a los ID que se maneja sin necesidad que el admin lo escriba en el excel.
          String grado = row[6]?.toString().trim() ?? '';
          String concatGradoId = 'G$grado';
          List<String> gradoIds = concatGradoId.split(',')?.map((g) => g.trim())?.toList() ?? [];

          String seccion = row[7]?.toString().trim() ?? '';
          String concatSeccionId = 'G$grado$seccion';
          List<String> seccionIds = concatSeccionId.split(',')?.map((s) => s.trim())?.toList() ?? [];

          if ([nombre, apellidoPaterno, apellidoMaterno, genero].every((cell) => cell == '') && gradoIds.isEmpty && seccionIds.isEmpty) continue; // Ignorar filas completamente vacías

          // Subir los datos del profesor a Firestore
          await FirebaseFirestore.instance.collection('AUXILIARES').doc(auxiliarId).set({
            'nombre': nombre,
            'apellido_paterno': apellidoPaterno,
            'apellido_materno': apellidoMaterno,
            'genero': genero,
            'cursoId': curso,
          });

          // Subir las secciones como subcolección
          for (var seccionId in seccionIds) {
            await FirebaseFirestore.instance
                .collection('AUXILIARES')
                .doc(auxiliarId)
                .collection('SECCIONES')
                .doc(seccionId)
                .set({});
          }
          for (var gradoId in gradoIds) {
            await FirebaseFirestore.instance
                .collection('AUXILIARES')
                .doc(auxiliarId)
                .collection('GRADOS')
                .doc(gradoId)
                .set({});
          }
        } on FirebaseException catch (e) {
          print('Error: $e');
        }
        if (hasEmptyCells) {
          if (mounted) {
            setState(() {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Error: Hay celdas vacías en el archivo. Por favor complete todas las celdas antes de subir.')));
            });
          }
        } else {
          if (mounted) {
            setState(() {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Datos subidos exitosamente a Firestore')));
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UploadPageAuxiliares()));
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al subir los datos a Firestore $e')));
        });
      }
    }
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
            onPressed:(){ Navigator.pop(context);}, 
            icon: Icon(Icons.arrow_back,color: whiteText,)),
          title: Text('Subir archivo de los auxiliares', style: TextStyle(
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
                        child: const Text('Seleccionar archivo'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _message,
                        style: TextStyle(
                            color: whiteText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      _data.isNotEmpty
                          ? Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: _data[0]
                                        .map((header) => DataColumn(
                                                label: Text(
                                              header.toString(),
                                              style: TextStyle(
                                                  color: whiteText,
                                                  ),
                                            )))
                                        .toList(),
                                    rows: _data
                                        .skip(1)
                                        .map(
                                          (row) => DataRow(
                                            cells: row
                                                .map((cell) =>
                                                    DataCell(Text(cell.toString(),style: TextStyle(
                                                      color: whiteColor
                                                    ),)))
                                                .toList(),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      //const SizedBox(height: 20),
                      _data.isNotEmpty
                          ? Column(
                            children: [
                            ElevatedButton(
                              onPressed: _uploadDataToFirestore,
                              child: Text('Almacenar en Firestore'),
                            ),
                            SizedBox(height: 30,),],)
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
