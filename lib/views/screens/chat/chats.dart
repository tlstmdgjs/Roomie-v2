import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:social_app_ui/util/chat_util.dart';
import 'package:social_app_ui/util/data.dart';
import 'package:social_app_ui/views/widgets/chat_item.dart';

class Chats extends StatefulWidget {
  final String email;
  Chats({
    super.key,
    required this.email,
  });
  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "채팅",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: chatsColRef.doc(widget.email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var chatsFromSnapshot = getChatsFromSnapshot(snapshot);
            return ListView.separated(
              padding: EdgeInsets.all(10),
              separatorBuilder: (BuildContext context, int index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 0.5,
                    width: MediaQuery.of(context).size.width / 1.3,
                    child: Divider(),
                  ),
                );
              },
              itemCount: chatsFromSnapshot.length,
              itemBuilder: (BuildContext context, int index) {
                Chat chat = chatsFromSnapshot[index];
                return ChatItem(
                  email: widget.email,
                  chat: chat,
                );
              },
            );
          } else
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: Colors.grey,
                size: 50,
              ),
            );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
