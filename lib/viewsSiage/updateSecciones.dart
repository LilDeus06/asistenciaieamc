import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'dart:convert';

class UploadPageSecciones extends StatefulWidget {

  @override
  _UploadPageSeccionesState createState() => _UploadPageSeccionesState();
}
    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);
class _UploadPageSeccionesState extends State<UploadPageSecciones> {
  bool _isLoading = false;
  String _message = '';
  List<List<dynamic>> _tableData = [];

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
        setState(() {
          _isLoading = false;
        });
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

  Future<void> _readCSV(File file) async {
    try {
      final input = file.openRead();
      final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();

      setState(() {
        _tableData = fields.map((row) {
          return row.map((cell) => cell == null || cell.toString().trim().isEmpty ? 'No registrado' : cell).toList();
        }).toList();
        _message = 'Datos cargados exitosamente desde CSV';
      });
    } catch (e) {
      setState(() {
        _message = 'Error al leer CSV: $e';
      });
    }
  }

  Future<void> _readExcel(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      var sheet = excel.tables[excel.tables.keys.first];
      setState(() {
        _tableData = sheet!.rows.map((row) {
          return row.map((cell) => cell == null || cell.value == null || cell.value.toString().trim().isEmpty ? 'No registrado' : cell.value).toList();
        }).toList();
        _message = 'Datos cargados exitosamente desde Excel';
      });
    } catch (e) {
      setState(() {
        _message = 'Error al leer Excel: $e';
      });
    }
  }

  Future<void> _uploadToFirestore() async {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: 
      Text('Subiendo datos a firestore...')));
    });
    try {
      // Filtrar y subir solo las filas válidas
      for (var i = 1; i < _tableData.length; i++) { // Saltar la cabecera
        var row = _tableData[i];
        String id = row[0].toString().trim();
        if (id.isNotEmpty && id != 'No registrado') {
          await FirebaseFirestore.instance.collection('SECCIONES').doc(id).set({
            'gradoId': row[1].toString().trim(),
            'letra': row[2].toString(),
          }, SetOptions(merge: true));
        }
      }
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Datos subidos exitosamente a Firestore')));
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir los datos a Firestore $e')));
      });
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
            onPressed: (){
              Navigator.pop(context);
            }, 
            icon: const Icon(Icons.arrow_back),color: whiteColor, ),
          title: Text('Subir archivo de las secciones', style: TextStyle(
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
                      _tableData.isNotEmpty
                          ? Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columns: _tableData[0].map((header) => DataColumn(label: Text(header.toString(),style: TextStyle(
                                    color: whiteText,
                                  ),))).toList(),
                                  rows: _tableData
                                      .skip(1)
                                      .map((row) {
                                        return DataRow(cells: row.map((cell) => DataCell(Text(cell.toString(),style: TextStyle(
                                          color: whiteColor
                                        ),))).toList());
                                      })
                                      .toList(),
                                ),
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 20),
                      _tableData.isNotEmpty
                          ? ElevatedButton(
                              onPressed: _uploadToFirestore,
                              child: const Text('Subir a Firestore'),
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
