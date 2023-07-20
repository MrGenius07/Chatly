// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cute_tinder/api/apis.dart';
import 'package:cute_tinder/helper/dialogs.dart';
import 'package:cute_tinder/models/chat_user.dart';
import 'package:cute_tinder/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
late Size mq;

// import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String ? _image;
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return GestureDetector(
      //For Hiding Keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Profile Screen'),
          ),

          // Floating Buttons to add new users
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 5),
            child: FloatingActionButton.extended(
              onPressed: () async {
                //Showing Progress Dialogs
                Dialogs.showProgressBar(context);


                await APIs.updateActiveStatus(false);
                //SIgn out from App
                await APIs.auth.signOut().then((value) async {
                  await GoogleSignIn().signOut().then((value) {
                    //For Hiding Progress Dialogs
                    Navigator.pop(context);
                    //For Moving to HOME SCREEN
                    Navigator.pop(context);

                    APIs.auth=FirebaseAuth.instance;
                    
                    //replacing Home Screen to Login Screen
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  });
                });
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),

          //body
          body: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      width: mq.width,
                      height: mq.height * .03,
                    ),

                    //User Profile Picture
                    Stack(
                      children: [
                        //Profile Picture
                        _image !=null
                        ?
                        
                        //Local Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(mq.height * 1),
                          child: Image.file(
                            File(_image!),
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover
                               
                          ),
                        ) 
                        :
                        //Image From Server
                         
                        ClipRRect(
                          borderRadius: BorderRadius.circular(mq.height * 1),
                          child: CachedNetworkImage(
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover,
                              imageUrl: widget.user.image,
                              errorWidget: (context, url, error) =>
                                  const CircleAvatar(
                                      child: Icon(CupertinoIcons.person))),
                        ),

                        //Edit Image button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MaterialButton(
                            elevation: 1,
                            onPressed: () {
                              _showottomSheet();
                            },
                            shape: const CircleBorder(),
                            color: Colors.white,
                            child: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      ],
                    ),

                    //For Adding some space
                    SizedBox(
                      height: mq.height * .03,
                    ),

                    //User Email
                    Text(
                      widget.user.email,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 16),
                    ),

                    //for Adding some space
                    SizedBox(
                      height: mq.height * .04,
                    ),
                    TextFormField(
                      initialValue: widget.user.name,
                      onSaved: (val) => APIs.me.name = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outlined,
                              color: Colors.blue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'eg. Chomu Singh',
                          label: const Text('Name')),
                    ),
                    SizedBox(
                      height: mq.height * .03,
                    ),
                    TextFormField(
                      initialValue: widget.user.about,
                      onSaved: (val) => APIs.me.about = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.info_outline,
                              color: Colors.blue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'eg. Feeling Tired',
                          label: const Text('About')),
                    ),
                    SizedBox(
                      height: mq.height * .033,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          shape: StadiumBorder(),
                          minimumSize: Size(mq.width * .5, mq.height * .06)),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          APIs.UpdateUserInfo().then((value) {
                            Dialogs.showSnackbar(
                                context, 'Profile Updated Successfully');
                          });
                          log('inside validator');
                        }
                      },
                      icon: const Icon(
                        Icons.edit,
                        size: 28,
                      ),
                      label: const Text(
                        'UPDATE',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )),
    );
  }

  //Bottom Sheet for profile picking for user
  void _showottomSheet() {
    showModalBottomSheet(
        context: context,
        shape:  const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              //Pick Profile Picture Label
              const Text(
                'Pick Profile Picture',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),

              SizedBox(height: mq.height*.02,),
                //Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //Pick From Gallery Button
                  ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: CircleBorder(),
                  fixedSize: Size( mq.width*.3, mq.height*.15)
                ),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  // Pick an image.
                  final XFile? image = 
                    await picker.pickImage(source: ImageSource.gallery);
                    if(image!=null){
                      log('Image Path ${image.path}  --Mime Type: ${image.mimeType}');
                      setState(() {
                        _image=image.path;
                      });

                      APIs.updateProfilePicture(File(_image!));
                      //For Hiding Bottom Sheet
                      Navigator.pop(context);
                    }

                }, 
                child: Image.asset(
                'images/add-image.png')),

                //Take Picture from Camera Buttons
                  ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: CircleBorder(),
                  fixedSize: Size( mq.width*.3, mq.height*.15)
                ),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  // Pick an image.
                  final XFile? image = 
                    await picker.pickImage(source: ImageSource.camera);
                    if(image!=null){
                      log('Image Path ${image.path}');
                      setState(() {
                        _image=image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      //For Hiding Bottom Sheet
                      Navigator.pop(context);
                    }
                }, child: Image.asset(
                'images/camera.png')),
              ],
              )
            ],
          );
        });
  }

}
