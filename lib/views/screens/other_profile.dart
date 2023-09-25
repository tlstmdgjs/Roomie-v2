import 'package:flutter/material.dart';
import 'package:social_app_ui/util/user.dart';
import 'package:social_app_ui/views/screens/detail.dart';

class OtherProfile extends StatelessWidget {
  final RoomieUser user;
  OtherProfile({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    print(user.email);
    print(user.essentials['studentNumber']);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "자세한 프로필",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_backspace,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Detail(user: user),
      ),
    );
  }
}
