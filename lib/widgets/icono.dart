import 'package:flutter/material.dart';

class IconoPerfil extends StatelessWidget {
  final Color fondoIconoClaro = const Color(0XFF0066FF);
  final Color fondoIconoOscuro = const Color(0XFF001220);

  const IconoPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fondoIconoOscuro,
        border: Border.all(
          color: fondoIconoClaro,
          width: 10,
        )
      ),
      child: 
      Icon(Icons.person ,color: fondoIconoClaro, size: 90,),
      
    );
  }
}