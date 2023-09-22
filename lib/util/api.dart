import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'package:http/http.dart';

class APIs {
// for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  //for storing self information
  static RoomieUser me = RoomieUser(
    email: auth.currentUser!.email!,
    essentials: RoomieUser.essentialInitialize(),
    survey: RoomieUser.answerInitialize(),
    pushToken: '',
  );

  //Push Notification
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
        print(t);

        me.setPushToken(t);
      }
    });
  }

  //for sending push notification
  static Future<void> sendPushNotification(
      RoomieUser roomieUser, String title, String msg) async {
    try {
      final body = {
        "to": roomieUser.pushToken,
        "notification": {"title": "$title", "body": "$msg"}
      };

      var res = await post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAAlTydX30:APA91bH5vYC6SJ39hlw57MAWQZXqrS58UH3TLi2yYJw4qwR-K-ipCyeHoqbM6n5f78jkU1u_iC22ewYTvGsnGVXQY-ekYMCN5whKjyD9JZY1uLMSaCXatxfw8nuJ3MpmPAFFPnH5T2Db',
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  static Future<void> sendMatchNotification(
      String token, String message) async {
    try {
      final body = {
        "to": token,
        "notification": {"title": "알림", "body": message}
      };

      var res = await post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key=AAAAlTydX30:APA91bH5vYC6SJ39hlw57MAWQZXqrS58UH3TLi2yYJw4qwR-K-ipCyeHoqbM6n5f78jkU1u_iC22ewYTvGsnGVXQY-ekYMCN5whKjyD9JZY1uLMSaCXatxfw8nuJ3MpmPAFFPnH5T2Db',
        },
        body: jsonEncode(body),
      );
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendMatchNotification Error: $e');
    }
  }

  static Future<void> sendCancelNotification(
      String token, String message) async {
    try {
      final body = {
        "to": token,
        "notification": {"title": "알림", "body": message}
      };

      var res = await post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              'key=AAAAlTydX30:APA91bH5vYC6SJ39hlw57MAWQZXqrS58UH3TLi2yYJw4qwR-K-ipCyeHoqbM6n5f78jkU1u_iC22ewYTvGsnGVXQY-ekYMCN5whKjyD9JZY1uLMSaCXatxfw8nuJ3MpmPAFFPnH5T2Db',
        },
        body: jsonEncode(body),
      );
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendMatchNotification Error: $e');
    }
  }

  //for checking if user exists or not?
  Future<bool> userExists() async {
    return (await firestore
            .collection('users')
            .doc(auth.currentUser!.uid)
            .get())
        .exists;
  }

  //for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((user) async {
      if (user.exists) {
        await getFirebaseMessagingToken();
        log("My Data: ${user.data()}");
        print(APIs.me.pushToken);
      }
    });
  }

  static Future<void> updatePushToken(String pushToken) async {
    String uid = auth.currentUser!.uid;

    await firestore.collection('users').doc(uid).update({
      'pushtoken': pushToken,
    });

    log('User push token updated.');
  }
}
