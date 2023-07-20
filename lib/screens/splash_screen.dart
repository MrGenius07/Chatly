import 'dart:developer';
import 'package:cute_tinder/api/apis.dart';
import 'package:cute_tinder/screens/auth/login_screen.dart';
import 'package:cute_tinder/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

late Size mq;

//Splash Screen for our app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      //Exit Full Screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(systemNavigationBarColor: Colors.white,statusBarColor: Colors.white));
      if (APIs.auth.currentUser != null) {
        log('\nUser : ${APIs.auth.currentUser}');
        //Navigate to Home Screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        //Navigate to login Screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        //App Logo
        Positioned(
            top: mq.height * .15,
            right: mq.width * .25,
            width: mq.width * .5,
            child: Image.asset('images/chat.png')),
        Positioned(
            bottom: mq.height * .15,
            width: mq.width,
            child: const Text(
              'Made by Genius 😉',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                  letterSpacing: .5),
            )),
      ]),
    );
  }
}
