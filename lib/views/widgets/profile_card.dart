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

class ProfileCard extends StatelessWidget {
  final User me, user;
  final List<String> highest, lowest;
  ProfileCard({
    super.key,
    required this.me,
    required this.user,
    this.highest = const [],
    this.lowest = const [],
  });

  @override
  Widget build(BuildContext context) {
    Owner profileMode = (me.email == user.email ? Owner.MINE : Owner.OTHERS);
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
                            user: me,
                            chat: Chat(
                              email: user.email,
                              nickname: user.essentials['nickname'],
                              conversations: [],
                            ),
                          ),
                        );
                      },
                    )
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
