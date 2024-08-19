import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:amc/helpers/navigatorProfesor.dart';
import 'package:amc/main.dart';

class FirebaseApi{
  //CREAREMOS LA INSTANCIA EN FIREBSE MESSAGING

  final _firebaseMessaging = FirebaseMessaging.instance;

  //FUNCION PARA INICIALIZAR NOTIFICACIONES
  Future<void> initNotifications () async {

  await _firebaseMessaging.requestPermission();
  
  final fCMToken = await _firebaseMessaging.getToken();

  print('token: $fCMToken');
  
  }

  //FNCION PARA RECIBIR MENSAJES

  // void handleMessage(RemoteMessage? message) {

  //   if (message == null) return;

  //   navigatorKey.currentState?.pushNamed(
  //     '/bienvenidaView',
  //     arguments: message,
  //   );
  // }

  // //FUNCION PARA INICIALIZAR DE FONDO LOS AJUSTES DE FONDO
  // Future initPushNotifications() async {

  //   FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

  //   FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

  // }
}