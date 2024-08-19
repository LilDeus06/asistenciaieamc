import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:amc/views/loginView.dart';
import 'package:amc/viewsSiage/gradosView.dart';
import 'package:amc/viewsSiage/mainSiageView.dart';


class NavigatorAdmin extends StatefulWidget {
  final AppUser user;

  const NavigatorAdmin({super.key, required this.user});

  @override
  State<NavigatorAdmin> createState() => _NavigatorAdminState();
}

class _NavigatorAdminState extends State<NavigatorAdmin> {
  
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  
  @override
  void initState(){
    super.initState();
    _widgetOptions = <Widget>[
      MainSiageView(user: widget.user),
      Gradosview(user: widget.user),
    ];
  }
  
  @override
  
  Widget build(BuildContext context) {
    
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      
        bottomNavigationBar: 
          Container(
              child: GNav(
              //padding: EdgeInsets.all(30),
              tabMargin: const EdgeInsets.only(top: 10, bottom:10, left: 20,right: 20),
              tabBackgroundColor: const Color.fromRGBO(7, 30, 48, 0.7),
              backgroundColor: const Color.fromRGBO(0, 18, 31, 1),
              tabBorderRadius: 100, 
              duration: const Duration(milliseconds: 400),
              tabs:const [
              GButton(
                icon:Icons.update,
                iconColor: Colors.white,
                iconActiveColor: Colors.white,
                text: "Añadir datos",
                textColor: Colors.white,
                ),
          
              GButton(
                icon: Icons.view_stream,
                iconColor: Colors.white,
                iconActiveColor: Colors.white,
                text: "Grados",
                textColor: Colors.white,
                ),
            ],
            
            selectedIndex: _selectedIndex, 
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            }
            )
          ),
        
      ),
    );
  }
}