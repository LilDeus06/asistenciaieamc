import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/viewsSiage/seccionesView.dart';



Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo1 = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color fondo2 = const Color(0XFF071E30);

class Gradosview extends StatefulWidget {
  final AppUser user;
  
  const Gradosview({ required this.user});
  

  @override
  State<Gradosview> createState() => _GradosViewState();
}

class _GradosViewState extends State<Gradosview> {
  Future<Map<String, dynamic>> getUserInfo() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('ADMINISTRADORES').doc(widget.user.dni).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getGrados() async {
    QuerySnapshot userDoc = await FirebaseFirestore.instance.collection('ADMINISTRADORES').doc(widget.user.dni).collection('GRADOS').get();
    List<dynamic> gradoIds = userDoc.docs.map((doc) => doc.id).toList();
    if(gradoIds.isEmpty){
      return [];
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('GRADOS').where(FieldPath.documentId,whereIn: gradoIds)
    .orderBy('numero', descending: false).get();
    
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
              padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
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
                        String greeting = userInfo['genero'] == 'Masculino' ? 'Bienvenido' : 'Bienvenida';
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
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: screenWidth,
              height: screenHeight * 0.72,
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
                  Container(
                    width: screenWidth*0.9,
                    height: screenHeight*0.6,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: getGrados(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
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
                          padding: const EdgeInsets.all(10),
                          itemBuilder: (context, index) {
                          return GestureDetector(
                          onTap: () {
                            Navigator.push(context,MaterialPageRoute(builder: (context) => SeccionesSiagePage(profesorUid: widget.user.dni,gradoId: grados[index]['id'],gradoNombre: grados[index]['nombre'],
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