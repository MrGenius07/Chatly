import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cute_tinder/helper/my_date_util.dart';
import 'package:cute_tinder/models/chat_user.dart';
import 'package:cute_tinder/models/message.dart';
import 'package:cute_tinder/screens/view_profile_screen.dart';
import 'package:cute_tinder/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/apis.dart';
import 'splash_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //For storing all messages
  List<Message> _list = [];

//for handelingmessage text change
  final _textController = TextEditingController();

  bool _showEmoji = false,_isUploading=false;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(()=>_showEmoji = !_showEmoji);
              return Future.value(false);
            } 
            else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            //APP Bar
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),
            backgroundColor: Color.fromRGBO(229, 248, 227, 0.918),

            //Body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //If data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();
                        //if some data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data
                                  ?.map((e) => Message.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                reverse: true,
                                itemCount: _list.length,
                                // padding: EdgeInsets.only(top: mq.height*.01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: _list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text(
                                'Say Hiii! 👋',
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),


                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          child: CircularProgressIndicator(strokeWidth: 2)
                          )),
                //chat input field
                _chatInput(),

                //Show emoji on keyboard emojis button
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController:
                          _textController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
                      config: Config(
                        bgColor: const Color.fromRGBO(229, 248, 227, 0.918),
                        columns: 8,
                        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }



  //App bar widget
  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_)=>ViewProfileScreen(user: widget.user)));
      },
      child: StreamBuilder(stream:APIs.getUsersInfo(widget.user ) ,builder: (context, snapshot) {
        final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? []; 
        return Row(
                children: [
                  //back button
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.black54)),

                  //user profile picture
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      width: mq.height * .05,
                      height: mq.height * .05,
                      imageUrl:
                          list.isNotEmpty ? list[0].image : widget.user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),

                  //for adding some space
                  const SizedBox(width: 10),

                  //user name & last seen time
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //user name
                      Text(list.isNotEmpty ? list[0].name : widget.user.name,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500)),

                      //for adding some space
                      const SizedBox(height: 2),

                      //last seen time of user
                      Text(
                          list.isNotEmpty
                              ? list[0].isOnline
                                  ? 'Online'
                                  : MydateUtil.getLastActiveTime(
                                      context: context,
                                      lastActive: list[0].lastActive)
                              : MydateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: widget.user.lastActive),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ],
                  )
                ],
              );
      })
    );
  }

  //Bottom Chat Input Field
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .02),
      child: Row(
        children: [
          //Input Field And Buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //Emoji Button
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showEmoji = !_showEmoji);
                    },
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                    color: Colors.black54,
                  ),

                  Expanded(
                    child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onTap: () {
                      if (_showEmoji)setState(() => _showEmoji = !_showEmoji);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Type Something... ',
                      hintStyle: TextStyle(color: Colors.blueAccent),
                      border: InputBorder.none,
                    ),
                  )),
                  //Pick image from Gallery
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();

                      //pick multiple image
                      final List<XFile>  images = 
                        await picker.pickMultiImage (imageQuality: 70);


                      //uploading and sending image one ny one
                        for (var i in images) {
                          log('Image Path : ${i.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImages(widget.user, File(i.path));
                           setState(() => _isUploading = false);
                        } 
                    },
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                    color: Colors.black54,
                  ),

                  //Pick image from Camera
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      // Pick an image.
                      final XFile? image = await picker.pickImage(
                          source: ImageSource.camera, imageQuality: 70);
                      if (image != null) {
                        log('Image Path ${image.path}');
                        setState(() => _isUploading = true);
                        await APIs.sendChatImages(
                            widget.user, File(image.path));
                            setState(() => _isUploading = false);
                      }
                    },
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                    color: Colors.black54,
                  ),
                  SizedBox(
                    width: mq.width * .02,
                  )
                ],
              ),
            ),
          ),

          //Send Message Button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                APIs.sendMessage(widget.user, _textController.text, Type.text);
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            color: const Color.fromARGB(255, 94, 190, 98),
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
