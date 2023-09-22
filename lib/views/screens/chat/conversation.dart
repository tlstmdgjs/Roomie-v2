import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app_ui/util/chat_util.dart';
import 'package:social_app_ui/util/data.dart';
import 'package:social_app_ui/util/enum.dart';
import 'package:social_app_ui/util/router.dart';
import 'package:social_app_ui/util/user.dart';
import 'package:social_app_ui/views/screens/other_profile.dart';
import 'package:social_app_ui/views/widgets/chat_bubble.dart';
import 'package:social_app_ui/util/api.dart';

class Conversation extends StatefulWidget {
  final String email;
  final Chat chat;
  Conversation({
    super.key,
    required this.email,
    required this.chat,
  });
  @override
  _ConversationState createState() => _ConversationState();
}

RoomieUser? otheruser;

class _ConversationState extends State<Conversation> {
  var controller = TextEditingController();

  void sendMatchingRequest(String senderEmail, String receiverEmail) async {
    try {
      CollectionReference matchingColRef =
          FirebaseFirestore.instance.collection('matching');

      Map<String, dynamic> request = {
        'senderEmail': senderEmail,
        'receiverEmail': receiverEmail,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await matchingColRef.add(request);
    } catch (e) {
      print('Error sending matching request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var chatDocRef = chatsColRef.doc(widget.email);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_backspace,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: FutureBuilder(
          future: usersColRef.doc(widget.email).get(),
          builder: (context, snapshot) {
            return InkWell(
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 0.0, right: 10.0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.chat.nickname,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          widget.chat.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () {
                if (snapshot.connectionState == ConnectionState.done) {
                  RoomieUser user = RoomieUser.fromFirestore(snapshot.data!);
                  Navigate.pushPage(
                    context,
                    OtherProfile(user: user),
                  );
                } else
                  null;
              },
            );
          },
        ),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(""),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("룸메이트를 신청하시겠습니까?"),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () async {
                            print("신청");

                            String receiverEmail = 'tmdgjs@jbnu.ac.kr';

                            sendMatchingRequest(widget.email, receiverEmail);

                            DocumentSnapshot<Map<String, dynamic>>
                                userSnapshot = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('tmdgjs@jbnu.ac.kr')
                                    .get();
                            if (userSnapshot.exists) {
                              String otherUserEmail =
                                  userSnapshot.data()!['email'];
                              String otherUserToken =
                                  userSnapshot.data()!['pushToken'];
                              otheruser = RoomieUser(
                                email: otherUserEmail,
                                essentials: RoomieUser.essentialInitialize(),
                                survey: RoomieUser.answerInitialize(),
                                pushToken: otherUserToken,
                              );
                            }
                            Future.delayed(Duration(milliseconds: 100), () {
                              APIs.sendPushNotification(
                                  otheruser!, "알림", "룸메이트 신청이 도착했습니다!");
                              print(otheruser!.pushToken);
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                          child: Text("신청"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                          child: Text("취소"),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.yellow,
              ),
              child: Text("신청"),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_horiz,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder(
        stream: chatDocRef.snapshots(),
        builder: (context, snapshot) {
          var chat = widget.chat;
          if (snapshot.hasData) {
            var conversations =
                (snapshot.data!.data()?[widget.chat.email] ?? []) as List;
            chat = Chat(
              email: chat.email,
              nickname: chat.nickname,
              conversations: conversations,
            );
          }
          return Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    itemCount: chat.conversations.length,
                    reverse: true,
                    itemBuilder: (BuildContext context, int index) {
                      var lastIndex = chat.conversations.length - 1;
                      var conversation = chat.conversations[lastIndex - index];
                      return ChatBubble(
                        conversation: conversation,
                        sender: conversation['sender'] == chat.email
                            ? Owner.OTHERS
                            : Owner.MINE,
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomAppBar(
                    elevation: 10,
                    color: Theme.of(context).colorScheme.secondary,
                    child: Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSecondary,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          width: MediaQuery.of(context).size.width - 25,
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          constraints: BoxConstraints(
                            maxHeight: 100,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: TextField(
                                  controller: controller,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    hintText: "메시지를 작성해주세요.",
                                    hintStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  cursorColor:
                                      Theme.of(context).colorScheme.secondary,
                                  maxLines: null,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.send,
                                ),
                                onPressed: () async {
                                  var typedToFirestore = chat.typedToFirestore(
                                      widget.email,
                                      controller.text,
                                      Owner.MINE);
                                  chatDocRef.update({
                                    FieldPath([chat.email]):
                                        FieldValue.arrayUnion(typedToFirestore)
                                  });
                                  typedToFirestore = chat.typedToFirestore(
                                      widget.email,
                                      controller.text,
                                      Owner.OTHERS);
                                  chatsColRef.doc(chat.email).update({
                                    FieldPath([widget.email]):
                                        FieldValue.arrayUnion(typedToFirestore)
                                  });

                                  DocumentSnapshot<Map<String, dynamic>>
                                      userSnapshot = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc('${chat.email}')
                                          .get();

                                  if (userSnapshot.exists) {
                                    String? otherUserEmail =
                                        userSnapshot.data()?['email'];
                                    if (otherUserEmail != null) {
                                      String otherUserToken =
                                          userSnapshot.data()!['pushToken'];
                                      otheruser = RoomieUser(
                                        email: otherUserEmail,
                                        essentials:
                                            RoomieUser.essentialInitialize(),
                                        survey: RoomieUser.answerInitialize(),
                                        pushToken: otherUserToken,
                                      );
                                      APIs.sendPushNotification(otheruser!,
                                          "${chat.nickname}", controller.text);
                                      print(otheruser!.pushToken);
                                      log("$controller.text");
                                    } else {
                                      print("email 존재하지 않음");
                                    }
                                  }
                                  controller.text = '';
                                  mounted ? setState(() {}) : dispose();
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
