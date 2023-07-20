import 'dart:io';
import 'dart:developer';
import 'package:cute_tinder/api/apis.dart';
import 'package:cute_tinder/helper/dialogs.dart';
import 'package:cute_tinder/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

late Size mq;
//Animated Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }


//Handle Google login button Click
  _handleGoogleBtnClick(){
    //For showing Progress bar
    Dialogs.showProgressBar( context);
    _signInWithGoogle().then((user) async {
    //For Hiding progress bar
      Navigator.pop(context);
      if(user!=null){
        log('\nUser : ${user.user}');
        log('\nUserAdditionalInfo : ${user.additionalUserInfo}');
        if((await APIs.UserExists())){
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_)=>const HomeScreen()));
        }
        else{
          await APIs.CreateUser().then((value){
            Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_)=>const HomeScreen()));
          });
        }
      }
    });
  }
  Future<UserCredential?> _signInWithGoogle() async {
    try{
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await APIs.auth.signInWithCredential(credential);
    }catch(e){
      log('\n_signInWithGoogle : $e');
      Dialogs.showSnackbar(context,'Net Connect kr Le Chomu😁');
      return null;
    }
  }

  //Sign out Function
  // _signOut() async{
  //   await FirebaseAuth.instance.signOut();
  //   await GoogleSignIn().signOut();
  // }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to Cute Tinder'),
        centerTitle: true,
      ),
      body: Stack(children: [
        //Animated Design
        AnimatedPositioned(
            top: mq.height * .15,
            right: _isAnimate ? mq.width * .25 : -mq.width * .5,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            child: Image.asset('images/chat.png')),
        Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .063,
            child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 152, 16),
                    shape: const StadiumBorder(),
                    elevation: 5),
                onPressed: () {
                  _handleGoogleBtnClick();
                },
                icon: Image.asset(
                  'images/googlee.png',
                  height: mq.height * .04,
                ),
                label: RichText(
                    text: const TextSpan(
                        style: TextStyle(fontSize: 16),
                        children: [
                      TextSpan(text: 'LogIn With '),
                      TextSpan(
                          text: 'Google',
                          style: TextStyle(fontWeight: FontWeight.w700))
                    ])))),
      ]),
    );
  }
}
