import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app_ui/util/user.dart';
import 'other_profile.dart';

class Noti extends StatefulWidget {
  final String email;
  Noti({super.key, required this.email});

  @override
  State<Noti> createState() => _NotiState();
}

class _NotiState extends State<Noti> {
  Stream<QuerySnapshot> getMatchingRequestsStream(String receiverEmail) {
    CollectionReference matchingColRef =
        FirebaseFirestore.instance.collection('matching');
    return matchingColRef
        .where('receiverEmail', isEqualTo: receiverEmail)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<RoomieUser> getUserData(String userEmail) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userEmail)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      return RoomieUser.fromFirestore(userData);
    } else {
      throw Exception('User data not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('알림'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: getMatchingRequestsStream(widget.email),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('오류발생: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('신청내역이 없습니다.'),
              );
            } else {
              List<QueryDocumentSnapshot> matchingRequests =
                  snapshot.data!.docs;
              return ListView.builder(
                  itemCount: matchingRequests.length,
                  itemBuilder: (context, index) {
                    QueryDocumentSnapshot requestSnapshot =
                        matchingRequests[index];
                    String senderEmail =
                        requestSnapshot['senderEmail'] as String;
                    Timestamp timestamp =
                        requestSnapshot['timestamp'] as Timestamp;
                    DateTime dateTime = timestamp.toDate();
                    String formattedTime =
                        "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
                    return ListTile(
                      title: Text(
                        '$senderEmail님이 룸메이트 신청을 요청했습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '$formattedTime',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      onTap: () async {
                        RoomieUser user = await getUserData(senderEmail);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfile(user: user),
                          ),
                        );
                      },
                    );
                  });
            }
          },
        ));
  }
}
