import 'dart:developer';
import 'package:cute_tinder/api/apis.dart';
import 'package:cute_tinder/models/chat_user.dart';
import 'package:cute_tinder/screens/profile_screen.dart';
import 'package:cute_tinder/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helper/dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message : ${message}');

      if(APIs.auth.currentUser!=null){
        if(message.toString().contains('resumed')){
        APIs.updateActiveStatus(true);
        }
        if(message.toString().contains('paused')){
        APIs.updateActiveStatus(false);
         }
      }

      
      return Future.value(message);

    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //For Hiding the keyboard when tap on the screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: (){
          if(_isSearching){
            setState(() {
              _isSearching=!_isSearching;
            });
          return Future.value(false);
          }else{

          return  Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            // leading: const Icon(CupertinoIcons.home),
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search With Name and Email'),
                    autofocus: true,
                    style: const TextStyle(fontSize: 16, letterSpacing: 1),
                    //When Search Text Changes Than update search List
                    onChanged: (val) {
                      //Search Logic
                      _searchList.clear();
                      for (var i in list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                        }
                        setState(() {
                          _searchList;
                        });
                      }
                    },
                  )
                : const Text('Cute Tinder'),
            actions: [
              //Search User Button
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  },
                  icon: Icon(_isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search)),
          
              //More Features Button
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: APIs.me)));
                  },
                  icon: const Icon(Icons.more_vert)),
            ],
          ),
          
          // Floating Buttons to add new users
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 5),
            child: FloatingActionButton(
              onPressed: (){
                _addChatUserDialog();
              },
              child: const Icon(Icons.add_comment_outlined),
            ),
          ),
          
          //body
          body: StreamBuilder(
            stream: APIs.getAllUsers(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                //If data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
                //if some data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  final data = snapshot.data?.docs;
                  list =
                      data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
          
                  if (list.isNotEmpty) {
                    return ListView.builder(
                        itemCount: _isSearching ? _searchList.length : list.length,
                        // padding: EdgeInsets.only(top: mq.height*.01),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return ChatUserCard(
                              user:
                                  _isSearching ? _searchList[index] : list[index]);
                          // return Text('Name : ${list[index]}');
                        });
                  } else {
                    return const Center(
                      child: Text(
                        'No Connection Found!',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
              }
            },
          ),
        ),
      ),
    );
  }



   // for adding new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text('  Add User')
                ],
              ),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: 'Email Id',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.blue, fontSize: 16))),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await APIs.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User does not Exists!');
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}
