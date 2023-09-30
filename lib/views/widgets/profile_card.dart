import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app_ui/util/chat_util.dart';
import 'package:social_app_ui/util/configs/list_config.dart';
import 'package:social_app_ui/util/enum.dart';
import 'package:social_app_ui/util/router.dart';
import 'package:social_app_ui/util/configs/theme_config.dart';
import 'package:social_app_ui/util/user.dart';
import 'package:social_app_ui/views/screens/chat/conversation.dart';
import 'package:social_app_ui/views/screens/other_profile.dart';
import 'package:social_app_ui/views/widgets/inprofile_button.dart';
import 'package:social_app_ui/util/api.dart';

class ProfileCard extends StatelessWidget {
  final String email;
  final RoomieUser user;
  final Owner profileMode;
  final List<String> highest, lowest;
  ProfileCard({
    super.key,
    required this.email,
    required this.user,
    this.profileMode = Owner.OTHERS,
    this.highest = const [],
    this.lowest = const [],
  });

  Future<void> sendMatchingRequest(
      String senderEmail, String receiverEmail) async {
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
    var highestVisualize = visualize(highest);
    var lowestVisualize = visualize(lowest);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red,
      ),
      width: ThemeConfig.cardWidth * 5.5,
      height: ThemeConfig.cardHeight * 5.5,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.essentials['nickname'],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  user.essentials['studentNumber'],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            SizedBox(
              height: 3,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user.essentials['major'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  ": ${user.survey['etc']}",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(
                  height: 12,
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 12,
              ),
              child: Visibility(
                visible: profileMode == Owner.OTHERS,
                child: Container(
                  height: 120,
                  width: 250,
                  decoration: BoxDecoration(
                      color: const Color(0xff028a0f),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "이런 점이 비슷해요",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: highestVisualize
                              .map(
                                (comm) => Text(
                                  comm,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                              .toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Visibility(
                visible: profileMode == Owner.OTHERS,
                child: Container(
                  height: 120,
                  width: 250,
                  decoration: BoxDecoration(
                      color: const Color(0xfffa8128),
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "이런 점이 달라요",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: lowestVisualize
                              .map(
                                (diff) => Text(
                                  diff,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                              .toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Visibility(
                visible: profileMode == Owner.OTHERS,
                child: Row(
                  children: [
                    InprofileButton(
                      icon: Icons.description,
                      label: '프로필',
                      onPressed: () {
                        Navigate.pushPage(
                          context,
                          OtherProfile(user: user),
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 9),
                    ),
                    InprofileButton(
                      icon: Icons.chat_bubble,
                      label: '새 채팅',
                      onPressed: () {
                        Navigate.pushPage(
                          context,
                          Conversation(
                            email: email,
                            chat: Chat(
                              email: user.email,
                              nickname: user.essentials['nickname'],
                              conversations: List.empty(),
                            ),
                          ),
                        );
                      },
                    ),
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

                                      String receiverEmail = email;

                                      sendMatchingRequest(email, receiverEmail);

                                      DocumentSnapshot<Map<String, dynamic>>
                                          userSnapshot = await FirebaseFirestore
                                              .instance
                                              .collection('users')
                                              .doc(receiverEmail)
                                              .get();
                                      if (userSnapshot.exists) {
                                        String otherUserEmail =
                                            userSnapshot.data()!['email'];
                                        String otherUserToken =
                                            userSnapshot.data()!['pushToken'];
                                        otheruser = RoomieUser(
                                          email: otherUserEmail,
                                          essentials:
                                              RoomieUser.essentialInitialize(),
                                          survey: RoomieUser.answerInitialize(),
                                          pushToken: otherUserToken,
                                        );
                                      }
                                      Future.delayed(
                                          Duration(milliseconds: 100), () {
                                        APIs.sendPushNotification(otheruser!,
                                            "알림", "룸메이트 신청이 도착했습니다!");
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
                                    onPressed: () {
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
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<String> visualize(List<String> est) {
    List<String> list = [];
    for (var item in est) {
      var tagIndex = questionList.indexOf(item) + 1;
      list.add(tagList[tagIndex]);
    }
    return list;
  }
}
