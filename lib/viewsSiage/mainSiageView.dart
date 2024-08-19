import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/viewsSiage/createUsers.dart';
import 'package:amc/viewsSiage/deleteUsers.dart';
import 'package:amc/viewsSiage/updateAlumnas.dart';
import 'package:amc/viewsSiage/updateAuxiliares.dart';
import 'package:amc/viewsSiage/updateSecciones.dart';
import 'package:amc/viewsSiage/updateProfesores.dart';


    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);

class MainSiageView extends StatelessWidget {
  final AppUser user;
  double separacionCards = 20;
  double heightCards = 100;
  double widthCards = 300;

  MainSiageView({required this.user});
  Future<Map<String, dynamic>> getUserInfo() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('ADMINISTRADORES').doc(user.dni).get();
    return userDoc.data() as Map<String, dynamic>;
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
        body:
            Container(
              width: screenWidth,
              height: screenHeight,
              color: fondo1,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenWidth*0.05),
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
                      Image(
                        image: const AssetImage('assets/images/Insignia_AMC.png'),
                        width: screenWidth*0.1,
                        height: screenHeight*0.1,
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Crear a los Usuarios",),
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateUsersPage()));
                          },
                        ),
                        SizedBox(height: separacionCards),
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Agregar Datos de los Profesores",),
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPageProfesores()));
                          },
                        ),
                        SizedBox(height: separacionCards),
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Agregar Datos de las Auxiliares",),
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPageAuxiliares()));
                          },
                        ),
                        SizedBox(height: separacionCards),
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Agregar Datos de las Secciones",),
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPageSecciones()));
                          },
                        ),
                        SizedBox(height: separacionCards),
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Agregar Datos de las Alumnas",),
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPageAlumna()));
                          },
                        ),
                        SizedBox(height: separacionCards),
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Agregar Datos de los Cursos",),
                          ),
                          onTap: (){
                            //Navigator.push(context, MaterialPageRoute(builder: (context) => UploadPageAlumna()));
                          },
                        ),
                        SizedBox(height: separacionCards),
                        GestureDetector(
                          child: Container(
                                      height: heightCards,
                                      width: widthCards,
                                      child: CardSubirDatos(texto: "Eliminar Datos de los Usuarios",),
                          ),
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DeletePageUsuarios()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
    );
  }
}

class CardSubirDatos extends StatelessWidget {
  String texto;
  CardSubirDatos({
    required this.texto,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
                        color: Colors.white,
                        elevation: 1,
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
                      texto,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white, // El color se aplicará como un degradado por ShaderMask
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
      ),
    ),
                          ],
                        ),
                      );
  }
}
