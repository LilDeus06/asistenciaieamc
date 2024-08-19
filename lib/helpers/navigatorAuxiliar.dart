import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/views/mainView.dart';
import 'package:amc/viewsAuxiliar/searchView.dart';
import 'package:amc/viewsAuxiliar/assistanceAux.dart';
import 'package:amc/viewsAuxiliar/profileAux.dart';

class NavigatorAuxiliar extends StatefulWidget {
  final AppUser user; //Cambiar el tipo de dato user a AppUser e importar la pagina loginView.dart porque ahi esta la clase creada

  const NavigatorAuxiliar({super.key, required this.user});

  @override
  State<NavigatorAuxiliar> createState() => _NavigatorAuxiliarState();
}

class _NavigatorAuxiliarState extends State<NavigatorAuxiliar> {
  
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  
  @override
  void initState(){
    super.initState();
    _widgetOptions = <Widget>[    
      Mainview(user: widget.user,),
      BuscarView(user: widget.user),
      AsistenciasPorMesView(profesorId: widget.user),
      ProfileAux(profesorId: widget.user),
    ];
  }
  
  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          color: const Color.fromRGBO(0, 18, 31, 1),
          child: GNav(
            tabMargin: const EdgeInsets.only(top: 2, bottom: 0),
            tabBackgroundColor: const Color.fromRGBO(7, 30, 48, 0.7),
            tabBorderRadius: 100,
            duration: const Duration(milliseconds: 400),
            gap: 8,
            color: Colors.white,
            activeColor: Colors.white,
            backgroundColor: const Color.fromRGBO(0, 18, 31, 1),
      
            tabs: const [
              GButton(
                icon: Icons.home,
                text: "Inicio",
              ),
              GButton(
                icon: Icons.search_rounded,
                text: "Buscar",
              ),
              GButton(
                icon: Icons.fact_check_outlined,
                text: "Asistencia",
              ),
              GButton(
                icon: Icons.person_pin,
                text: "Perfil",
              ),
            ],
            selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },)
        ),
      ),
    );
  }
}