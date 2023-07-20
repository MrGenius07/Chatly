// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cute_tinder/models/chat_user.dart';
import 'package:cute_tinder/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

class APIs {
  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //For accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //For accessing cloud firestore database
  static FirebaseStorage storage = FirebaseStorage.instance;

  //to return current user
  static User get user => auth.currentUser!;

  //For Storing Self Info
  static late ChatUser me;

  //for acessing firebase messeging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;
  //For getting firebase messiging Tokan
  static Future<void> getFirebaseMessagingTokan() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token :$t');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }


    // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }
  //For sending Push notification
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": me.name, //our name should be send
          "body": msg,
          "android_channel_id": "chats"
        },
        "data": {
          "some_data": "User ID: ${me.id}",
        },
      };
      var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAA3WzmgXI:APA91bGZgLb9DpNrjZmcFYewX5TS8j9Z4PzzHuerhQ0vrA8TLXIX1LyGpKWogRXoHxvltyiIIJfnUjBtmgUbK4wC2bnhuSq9nNjeQI080GcJnX86CfTKEaR03dr4iAt7vtt-F50Q1kgB'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  //for checking is user exist or not
  static Future<bool> UserExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  //For Getting Current User Info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingTokan();
        //for setting user status to active
        APIs.updateActiveStatus(true);
        log('My Data : ${user.data()}');
      } else {
        await CreateUser().then((value) => getSelfInfo());
      }
    });
  }

  //for creating new user
  static Future<void> CreateUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
        image: user.photoURL.toString(),
        about: " Hey, I'm Using Cute Tinder",
        name: user.displayName.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        id: user.uid,
        email: user.email.toString(),
        pushToken: '');
    return (await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson()));
  }

  //For Getting All users from Firestore Database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  //for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUsersInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  //update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  //Update User Information
  static Future<void> UpdateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  //Update Profile Picture of user
  static Future<void> updateProfilePicture(File file) async {
    //Getting image file extension
    final ext = file.path.split('.').last;
    log('Extension :$ext');

    //Storage File raf with path
    final ref = storage.ref().child('Profile_Picture/${user.uid}.$ext');

    //Uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transfer : ${p0.bytesTransferred / 1000} kb');
    });

    //Updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({
      'image': me.image,
    });
  }

  ///***************************Chat Screen Realated APIS****************************/

  //Useful for Getting Converation id
  static String getConverationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  //For Getting All all messagesof s specific conversation from Firestore Database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser ChatUser) {
    return firestore
        .collection('chats/${getConverationID(ChatUser.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  //for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    //Message sending time also used as id
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final Message message = Message(
        toid: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        fromid: user.uid,
        sent: time);

    final ref = firestore
        .collection('chats/${getConverationID(chatUser.id)}/messages/');
    ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConverationID(message.fromid)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessages(
      ChatUser ChatUser) {
    return firestore
        .collection('chats/${getConverationID(ChatUser.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //Sent images in chat
  static Future<void> sendChatImages(ChatUser chatUser, File file) async {
    //Getting image file extension
    final ext = file.path.split('.').last;

    //Storage File raf with path
    final ref = storage.ref().child(
        'images/${getConverationID(chatUser.id)} /${DateTime.now().millisecondsSinceEpoch}.$ext');

    //Uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transfer : ${p0.bytesTransferred / 1000} kb');
    });

    //Updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }
  //Chat(Collections)-->conversation_id(doc)  --> messages(Collections)  -->message(Doc)


  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConverationID(message.toid)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConverationID(message.toid)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
