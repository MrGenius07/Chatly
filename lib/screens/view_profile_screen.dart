import 'package:cached_network_image/cached_network_image.dart';
import 'package:cute_tinder/helper/my_date_util.dart';
import 'package:cute_tinder/models/chat_user.dart';
import 'package:cute_tinder/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// import '../main.dart';
//view profile screen to view profile of user
class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //For Hiding Keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(widget.user.name),
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Joined On :  ',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 16),
              ),
              Text(
                MydateUtil.getLastMessageTime(context: context, time: widget.user.createdAt,showYear: true),
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ],
          ),


          

          //body
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: mq.width,
                    height: mq.height * .03,
                  ),

                  //User Profile Picture
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

                  //For Adding some space
                  SizedBox(
                    height: mq.height * .03,
                  ),

                  //User Email
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),

                  //for Adding some space
                  SizedBox(
                    height: mq.height * .04,
                  ),

                  //user About
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'About:  ',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 15),
                      ),
                      Text(
                        widget.user.about,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
