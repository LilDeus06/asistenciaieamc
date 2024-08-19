import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:amc/views/loginView.dart';
import 'package:http/http.dart' as http;

class AdminPanel extends StatefulWidget {
  final AppUser user;

  const AdminPanel({required this.user});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _rolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subscribeToTopic();
  }

  void _subscribeToTopic() async {
    try {
      await _messaging.subscribeToTopic('all');
      print('Subscribed to topic "all"');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(   
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(color:const Color(0XFF071E30),),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5,),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(child: Text("ADMIN PANEL", 
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                    ),
                  )),
                ),
              const SizedBox(height: 20,),
              // Bloque de Usuarios Conectados
              const Text('Usuarios Conectados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('USUARIOS').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var user = snapshot.data!.docs[index];
                      bool isConnected = user['isConnected'] ?? true;
                      return ListTile(
                        title: Text(user['email'], style: const TextStyle(color: Colors.white)),
                        trailing: Icon(
                          isConnected ? Icons.circle : Icons.circle,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20),
        
              // Bloque de Añadir/Quitar Usuarios
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                      const Text('Añadir/Quitar Usuarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 20),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email',border: OutlineInputBorder(),labelStyle: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(),labelStyle: TextStyle(color: Colors.white60)),
                        obscureText: true,
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: _dniController,
                        decoration: const InputDecoration(labelText: 'DNI', border: OutlineInputBorder(),labelStyle: TextStyle(color: Colors.white60)),
                        maxLength: 8,
                        canRequestFocus: true,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: _rolController,
                        decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder(),labelStyle: TextStyle(color: Colors.white60)),
        
                      ),
        
                      const SizedBox(height: 20,),
        
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _addUser,
                            child: const Text('Añadir Usuario'),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _deleteUser,
                            child: const Text('Quitar Usuario'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
        
              
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addUser() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,

      );
      await _firestore.collection('USUARIOS').doc(userCredential.user!.uid).set({
        'email': _emailController.text,
        'isConnected': false,
        'rol': _rolController.text,
        'dni': _dniController.text,
        'contraseña': _passwordController.text,
      });
      _emailController.clear();
      _passwordController.clear();
      _dniController.clear();
      _rolController.clear();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _deleteUser() async {
    try {
      var user = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _firestore.collection('USUARIOS').doc(user.user!.uid).delete();
      await user.user!.delete();
      _emailController.clear();
      _passwordController.clear();
      _dniController.clear();
      _rolController.clear();
    } catch (e) {
      print("Error: $e");
    }
  }
}
