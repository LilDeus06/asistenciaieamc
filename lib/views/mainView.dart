import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/views/seccionesProfesoresView.dart';
import 'package:amc/zeos/ViewSecret.dart';



Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);

class Mainview extends StatefulWidget {
  final AppUser user; //Cambiar el tipo de dato user a AppUser e importar la pagina loginView.dart porque ahi esta la clase creada
  
  const Mainview({ required this.user});
  

  @override
  State<Mainview> createState() => _MainviewState();
}

class _MainviewState extends State<Mainview> {
  int _tapCount = 0;
DateTime? _lastTapTime;

void _handleTap() {
  final now = DateTime.now();
  if (_lastTapTime == null || now.difference(_lastTapTime!) > Duration(seconds: 4)) {
    _tapCount = 1;
  } else {
    _tapCount++;
  }
  _lastTapTime = now;

  if (_tapCount == 5) {
    _showSecretViewMessage();
    _tapCount = 0;
  }
}

void _showSecretViewMessage() {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('¡Vista secreta activada!', style: TextStyle(fontSize: 17),),
      duration: Duration(seconds: 2),
      action: SnackBarAction(
        label: 'Abrir',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SecretView()),
          );
        },
      ),
    ),
  );
}
  Future<Map<String, dynamic>> getUserInfo() async {
    // Primero buscamos en la colección 'PROFESORES'
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('PROFESORES')
        .doc(widget.user.dni)
        .get();

    // Si encontramos datos, los retornamos
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }

    // Si no encontramos datos en 'PROFESORES', buscamos en 'OWNER'
    userDoc = await FirebaseFirestore.instance
        .collection('OWNERS')
        .doc(widget.user.dni)
        .get();

    // Si encontramos datos en 'OWNER', los retornamos
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    // Si no encontramos datos en 'PROFESORES', buscamos en 'OWNER'
    userDoc = await FirebaseFirestore.instance
        .collection('AUXILIARES')
        .doc(widget.user.dni)
        .get();

    // Si encontramos datos en 'OWNER', los retornamos
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }

    // Si no encontramos datos en ninguna de las colecciones, retornamos un mapa vacío o lanzamos una excepción
    return {}; // Puedes personalizar este comportamiento
  }

  Future<List<Map<String, dynamic>>> getGrados() async {

    List<String> collections = ['PROFESORES', 'AUXILIARES', 'OWNERS'];
    String collectionPath = '';
    DocumentSnapshot? userDoc;
    for (String collection in collections) {
      userDoc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(widget.user.dni)
        .get();
    if (userDoc.exists) {
      collectionPath = collection;
      break;
    }
    }
    if (userDoc == null || !userDoc.exists) {
    throw Exception('Usuario no encontrado en ninguna colección');
    }
    QuerySnapshot subcollectionSnapshot = await FirebaseFirestore.instance
      .collection(collectionPath)
      .doc(widget.user.dni)
      .collection('GRADOS')
      .get();
  List<String> gradoIds = subcollectionSnapshot.docs.map((doc) => doc.id).toList();
    // Suponiendo que el campo 'gradoId' tiene la misma estructura en ambas colecciones
    //List<dynamic> gradoIds = userData['gradoId'];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('GRADOS')
        .where(FieldPath.documentId, whereIn: gradoIds)
        .orderBy('numero', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'nombre': doc['nombre'],
              'numero': doc['numero'],
            })
        .toList();
  }


  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    TextStyle texto = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: whiteText,
    );

    return SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                child:Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: fondo1,
                ) ,
              ),
              Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: getUserInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: texto,);
                        } else {
                          Map<String, dynamic> userInfo = snapshot.data!;
                          String greeting = userInfo['genero'].toString().toUpperCase() == 'MASCULINO' ? 'Bienvenido' : 'Bienvenida';
                          return Text('$greeting, ${userInfo['nombre']} ${userInfo['apellido_paterno']}',style:  texto,);
                        }
                      },
                    ),
                    GestureDetector(
                    onTap: () {
                      _handleTap();
                    },
                    child: SizedBox(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      child: Image.asset(
                        'assets/images/Insignia_AMC.png',
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight * 0.77,
                decoration: BoxDecoration(
                  color: fondo2,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
                ),
                child:  Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.check_box, color: whiteText,size: 30 ,),
                          const SizedBox(width: 5),
                          Text("Seleccione el grado", style: texto,)
                        ],
                      ),
                    ),
                    Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: getGrados(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text(" ");
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('No tienes grados asignados'));
                            } else {
                              List<Map<String, dynamic>> grados = snapshot.data!;
                              return GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.9,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: grados.length,
                                padding: const EdgeInsets.all(20),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SeccionesProfesoresPage(
                                            profesorUid: widget.user,gradoId: 
                                            grados[index]['id'],
                                            gradoNombre: grados[index]['nombre']
                                          ),
                                        ),
                                      );
                                    },
                                    child: GradoCard(
                                      numero: grados[index]['numero'],
                                      nombre: grados[index]['nombre'],
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            )
            ],
          ),
        ),
      );
  }
}

class GradoCard extends StatelessWidget {
  final int numero;
  final String nombre;

  GradoCard({required this.numero, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>  LinearGradient(
              colors: [fondo1 , lightBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              numero.toString(),
              style: const TextStyle(
                fontSize: 80,
                color: Colors.white, // El color se aplicará como un degradado por ShaderMask
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            nombre,
            style:  const TextStyle(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}