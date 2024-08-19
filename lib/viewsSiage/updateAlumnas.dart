import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'dart:convert';


class UploadPageAlumna extends StatefulWidget {

  

  @override
  _UploadPageAlumnaState createState() => _UploadPageAlumnaState();
}
  Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);

class _UploadPageAlumnaState extends State<UploadPageAlumna> {
  
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
        if (id.isNotEmpty && id != 'No registrado' && RegExp(r'^\d{8}$').hasMatch(id)) {
          String grado = row[4].toString().trim();
          String seccion = row[5].toString().trim();
          String seccionId = 'G$grado$seccion';

          await FirebaseFirestore.instance.collection('ALUMNAS').doc(id).set({
            'nombre': row[1].toString().trim(),
            'apellido_paterno': row[2].toString().trim(),
            'apellido_materno': row[3].toString().trim(),
            'seccionId': seccionId,
            'genero': row[6].toString().trim(),
            'dni_apoderado': row[7].toString().trim(),
            'apellidos_nombre_apoderado': row[8].toString().trim(),
            'parentesco_apoderado': row[9].toString().trim(),
            'celular_apoderado': row[10].toString().trim(),
            'auxiliarId': row.length > 12 ? row[12].toString().trim() : null,
          }, SetOptions(merge: true));
        }
      }
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Datos subidos exitosamente a Firestore')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UploadPageAlumna() ));  
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(
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
            icon: Icon(Icons.arrow_back,color: whiteColor,)),
          title: Text('Subir Archivo de Alumnas',style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.w600
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
                        color: whiteColor,
                        fontSize: 14,
                      ),),
                      const SizedBox(height: 20),
                      _tableData.isNotEmpty
                          ? Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    columns: _tableData[0].map((header) => DataColumn(label: Text(header.toString(), style: TextStyle(
                                      color: whiteText
                                    ),))).toList(),
                                    rows: _tableData
                                        .skip(1)
                                        .where((row) {
                                          String id = row[0].toString().trim();
                                          return id.isNotEmpty && id != 'No registrado' && RegExp(r'^\d{8}$').hasMatch(id);
                                        })
                                        .map((row) {
                                          final filledRow = List<dynamic>.from(row);
                                          while (filledRow.length < _tableData[0].length) {
                                            filledRow.add('No registrado');
                                          }
                                          return DataRow(cells: filledRow.map((cell) => DataCell(Text(cell.toString(),style: TextStyle(
                                            color: whiteText
                                          ),))).toList());
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      const SizedBox(height: 20),
                      _tableData.isNotEmpty
                          ? Column(
                            children: [
                            ElevatedButton(
                              onPressed: _uploadToFirestore,
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
