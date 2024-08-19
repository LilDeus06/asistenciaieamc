import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:amc/views/loginView.dart';

class ResetPasswordPage extends StatefulWidget {
  
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

    Color whiteColor = const Color(0XFFF6F6F6);
    Color lightBlue = const Color(0XFF0066FF);
    Color fondo = const Color(0XFF001220);
    Color whiteText = const Color(0XFFF3F3F3);
    Color input = const Color(0XFFD3E5FF);
    
  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Correo Enviado'),
            content: const Text('Se ha enviado un correo para restablecer tu contraseña.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              child: Container(
                width: screenWidth,
                height: screenHeight,
                color: fondo,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child:  CustomPaint(
                size:  Size(screenWidth*0.4, screenHeight*0.2),
                painter: WavePainter(),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child:Transform.rotate(
              angle: 3.14159,
              child: CustomPaint(
                size:  Size(screenWidth*0.4, screenHeight*0.2),
                painter: WavePainter(),
              ),
            ),),
            SingleChildScrollView(
              child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight*0.1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    Center(
                        child: Image(
                          image: const AssetImage('assets/images/Insignia_AMC.png'),
                          width: screenWidth*0.3,
                          height: screenHeight*0.2,),
                      ),
                    const SizedBox(height: 20,),
                    Text('INGRESE SU CORREO REGISTRADO',style: TextStyle(
                      color: whiteText,
                      fontWeight: FontWeight.bold,
                      fontSize: 22
                    ),
                    textAlign: TextAlign.center,),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth*0.1,vertical: screenHeight*0.025),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: input,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su correo electrónico';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Por favor ingrese un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightBlue, // Color del texto del botón
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.email,
                      color: whiteColor,), // Icono del botón
                      label: Text('ENVIAR CORREO',style: TextStyle(
                        color: whiteColor
                      ),), // Texto del botón
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
                  ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: false,
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0XFF0066FF) // Color de la forma
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0); // Empezar en la esquina superior derecha
    path.lineTo(size.width, size.height * 1); // Línea hacia abajo

    // Dibujar curvas
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 1,
      size.width * 0.7,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.6,
      size.width * 0.35,
      size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.6,
      size.width * 0.4,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0,
      size.height * 0,
    );

    path.lineTo(0, 0); // Línea hasta la esquina superior izquierda
    path.close(); // Cerrar el camino

    canvas.drawPath(path, paint); // Dibujar la forma en el lienzo
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}